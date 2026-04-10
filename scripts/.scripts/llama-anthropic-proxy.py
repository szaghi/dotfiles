#!/usr/bin/env python3
"""
Minimal Anthropic Messages API → OpenAI Chat Completions proxy.

Bridges Claude Code (which speaks the Anthropic SDK protocol) to
llama-server (which exposes only an OpenAI-compatible /v1/chat/completions
endpoint).

Usage (managed by llama-proxy-start / llama-proxy-stop in ~/.bash/claude_code):
    python3 ~/.scripts/llama-anthropic-proxy.py [--host H] [--port P] [--backend URL]

Defaults:
    --host    127.0.0.1
    --port    4000
    --backend http://127.0.0.1:8080
"""

import argparse
import json
import sys
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.error import URLError
from urllib.request import Request, urlopen


# ── Translation helpers ────────────────────────────────────────────────────────

def _content_to_str(content) -> str:
    """Flatten Anthropic content (str or list of blocks) to a plain string."""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return "".join(
            block.get("text", "")
            for block in content
            if isinstance(block, dict) and block.get("type") == "text"
        )
    return str(content)


def anthropic_to_openai(body: dict, no_think: bool = False) -> dict:
    """Convert an Anthropic Messages request body to OpenAI Chat Completions.

    no_think: append /no_think to the system prompt to disable extended reasoning
    on Qwen3.5 and similar thinking models.
    """
    messages = []

    # System prompt → prepend as system role message
    system = body.get("system")
    sys_text = _content_to_str(system) if system else ""
    if no_think:
        sys_text = (sys_text + "\n/no_think").lstrip()
    if sys_text:
        messages.append({"role": "system", "content": sys_text})

    for msg in body.get("messages", []):
        messages.append({
            "role": msg["role"],
            "content": _content_to_str(msg.get("content", "")),
        })

    oai: dict = {
        "model": body.get("model", "local"),
        "messages": messages,
        "stream": body.get("stream", False),
    }
    for key in ("max_tokens", "temperature", "top_p", "top_k", "stop"):
        if key in body:
            oai[key] = body[key]

    return oai


def openai_to_anthropic(oai: dict, model: str) -> dict:
    """Convert an OpenAI completion response to Anthropic message format."""
    choice = oai.get("choices", [{}])[0]
    text = choice.get("message", {}).get("content", "")
    usage = oai.get("usage", {})
    return {
        "id": "msg_" + uuid.uuid4().hex[:24],
        "type": "message",
        "role": "assistant",
        "content": [{"type": "text", "text": text}],
        "model": model,
        "stop_reason": "end_turn",
        "stop_sequence": None,
        "usage": {
            "input_tokens": usage.get("prompt_tokens", 0),
            "output_tokens": usage.get("completion_tokens", 0),
        },
    }


def iter_anthropic_stream(oai_response, model: str):
    """
    Consume an OpenAI SSE stream and yield Anthropic SSE event strings.
    Each yielded value is a complete 'event: …\ndata: …\n\n' block.
    """
    msg_id = "msg_" + uuid.uuid4().hex[:24]

    def ev(event_type: str, data: dict) -> str:
        return f"event: {event_type}\ndata: {json.dumps(data)}\n\n"

    yield ev("message_start", {
        "type": "message_start",
        "message": {
            "id": msg_id, "type": "message", "role": "assistant",
            "content": [], "model": model,
            "stop_reason": None, "stop_sequence": None,
            "usage": {"input_tokens": 0, "output_tokens": 0},
        },
    })
    yield ev("content_block_start", {
        "type": "content_block_start", "index": 0,
        "content_block": {"type": "text", "text": ""},
    })
    yield 'event: ping\ndata: {"type":"ping"}\n\n'

    output_tokens = 0
    for raw in oai_response:
        line = raw.decode("utf-8").rstrip()
        if not line.startswith("data: "):
            continue
        payload = line[6:]
        if payload == "[DONE]":
            break
        try:
            chunk = json.loads(payload)
        except json.JSONDecodeError:
            continue

        choices = chunk.get("choices") or []
        if not choices:
            continue
        delta = choices[0].get("delta", {})
        text = delta.get("content") or ""
        if text:
            output_tokens += 1  # token count approximation
            yield ev("content_block_delta", {
                "type": "content_block_delta", "index": 0,
                "delta": {"type": "text_delta", "text": text},
            })
        if choices[0].get("finish_reason"):
            break

    yield ev("content_block_stop", {"type": "content_block_stop", "index": 0})
    yield ev("message_delta", {
        "type": "message_delta",
        "delta": {"stop_reason": "end_turn", "stop_sequence": None},
        "usage": {"output_tokens": output_tokens},
    })
    yield 'event: message_stop\ndata: {"type":"message_stop"}\n\n'


# ── HTTP handler ───────────────────────────────────────────────────────────────

class ProxyHandler(BaseHTTPRequestHandler):
    """Forward /v1/messages (Anthropic) → backend /v1/chat/completions (OpenAI)."""

    def log_message(self, fmt, *args):
        # Silent by default; set LLAMA_PROXY_VERBOSE=1 to enable
        import os
        if os.environ.get("LLAMA_PROXY_VERBOSE"):
            print(f"[proxy] {fmt % args}", file=sys.stderr, flush=True)

    def _backend(self) -> str:
        return self.server.backend  # type: ignore[attr-defined]

    def _json_response(self, body: dict, code: int = 200):
        data = json.dumps(body).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_HEAD(self):
        # Claude Code does a HEAD / connectivity check before starting a session.
        self.send_response(200)
        self.end_headers()

    def do_GET(self):
        from urllib.parse import urlparse
        path = urlparse(self.path).path

        if path == "/health":
            self._json_response({"status": "ok"})

        elif path == "/v1/models":
            # Claude Code lists models to populate /model picker — return a stub entry.
            self._json_response({
                "data": [{
                    "type": "model",
                    "id": "llama",
                    "display_name": "llama.cpp",
                    "created_at": "2024-01-01T00:00:00Z",
                }],
                "has_more": False,
                "first_id": "llama",
                "last_id": "llama",
            })

        elif path.startswith("/v1/models/"):
            # Claude Code validates the model by ID before starting a session.
            # Accept any name — llama-server ignores the model field anyway.
            model_id = path[len("/v1/models/"):]
            self._json_response({
                "type": "model",
                "id": model_id,
                "display_name": model_id,
                "created_at": "2024-01-01T00:00:00Z",
            })

        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        from urllib.parse import urlparse
        if urlparse(self.path).path != "/v1/messages":
            self.send_response(404)
            self.end_headers()
            return

        length = int(self.headers.get("Content-Length", 0))
        try:
            body = json.loads(self.rfile.read(length))
        except (json.JSONDecodeError, ValueError) as exc:
            self._error(400, str(exc))
            return

        model = body.get("model", "local")
        stream = body.get("stream", False)

        oai_body = anthropic_to_openai(body, no_think=getattr(self.server, "no_think", False))
        req = Request(
            f"{self._backend()}/v1/chat/completions",
            data=json.dumps(oai_body).encode(),
            headers={"Content-Type": "application/json"},
            method="POST",
        )

        try:
            resp = urlopen(req, timeout=600)
        except URLError as exc:
            self._error(502, f"llama-server unreachable: {exc.reason}")
            return
        except Exception as exc:
            self._error(502, str(exc))
            return

        if stream:
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.send_header("Cache-Control", "no-cache")
            self.end_headers()
            try:
                for chunk in iter_anthropic_stream(resp, model):
                    self.wfile.write(chunk.encode())
                    self.wfile.flush()
            except BrokenPipeError:
                pass
        else:
            try:
                oai_resp = json.loads(resp.read())
            except Exception as exc:
                self._error(502, f"bad response from llama-server: {exc}")
                return
            anthr = openai_to_anthropic(oai_resp, model)
            body_out = json.dumps(anthr).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body_out)))
            self.end_headers()
            self.wfile.write(body_out)

    def _error(self, code: int, message: str):
        body = json.dumps({"error": {"type": "proxy_error", "message": message}}).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)
        print(f"[proxy] error {code}: {message}", file=sys.stderr)


# ── Entry point ────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Anthropic Messages API → OpenAI Chat Completions proxy"
    )
    parser.add_argument("--host",     default="127.0.0.1")
    parser.add_argument("--port",     type=int, default=4000)
    parser.add_argument("--backend",  default="http://127.0.0.1:8080",
                        help="llama-server base URL")
    parser.add_argument("--no-think", action="store_true",
                        help="append /no_think to system prompt (disables extended reasoning "
                             "on Qwen3.5 and similar thinking models)")
    args = parser.parse_args()

    server = ThreadingHTTPServer((args.host, args.port), ProxyHandler)
    server.backend = args.backend    # type: ignore[attr-defined]
    server.no_think = args.no_think  # type: ignore[attr-defined]
    print(
        f"[proxy] Anthropic proxy listening on http://{args.host}:{args.port}"
        f" → {args.backend}",
        file=sys.stderr,
        flush=True,
    )
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("[proxy] shutting down", file=sys.stderr)


if __name__ == "__main__":
    main()
