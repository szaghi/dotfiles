"""PreToolUse hook (Bash): block git commits that carry an AI co-author trailer.

Deterministic backstop for the CLAUDE.md rule "NEVER add Co-authored-by lines for Claude or
any AI". Exit 2 blocks the call and tells Claude why. It sees only the command line, so a
message passed with -F or written in an editor is not checked (the commit-msg hook covers
those, where installed).
"""

from __future__ import annotations

import json
import re
import sys

COMMIT = re.compile(r"\bgit\b[^|;&]*\bcommit\b")
AI = r"[^\n]*(claude|anthropic|copilot|openai|chatgpt|gemini|cursor)"
# Trailer position only: a line that starts with the trailer, or git's --trailer option.
# A subject that merely mentions "co-authored-by: Claude" is not a trailer.
AI_TRAILER = re.compile(
    rf"(^\s*co-authored-by:{AI})|(--trailer[=\s]+[\"']?co-authored-by[:=]{AI})",
    re.IGNORECASE | re.MULTILINE,
)


def main() -> int:
    event = json.load(sys.stdin)
    command = event.get("tool_input", {}).get("command", "")
    if COMMIT.search(command) and AI_TRAILER.search(command):
        print(
            "BLOCKED: this commit message carries an AI Co-authored-by trailer. "
            "Remove the trailer; AI co-authorship is not recorded in Stefano's commits.",
            file=sys.stderr,
        )
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
