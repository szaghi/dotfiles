#!/usr/bin/env python3
"""
Research Information Lookup Tool

Runs research queries against the Parallel Chat API (core model).

Environment variables:
  PARALLEL_API_KEY    - Required for the Parallel Chat API
"""

import os
import sys
import json
import re
import time
from datetime import datetime
from typing import Any, Dict, List


class ResearchLookup:
    """Research information lookup via the Parallel Chat API."""

    PARALLEL_SYSTEM_PROMPT = (
        "You are a deep research analyst. Provide a comprehensive, well-cited "
        "research report on the user's topic. Include:\n"
        "- Key findings with specific data, statistics, and quantitative evidence\n"
        "- Detailed analysis organized by themes\n"
        "- Multiple authoritative sources cited inline\n"
        "- Methodologies and implications where relevant\n"
        "- Future outlook and research gaps\n"
        "Use markdown formatting with clear section headers. "
        "Prioritize authoritative and recent sources."
    )

    CHAT_BASE_URL = "https://api.parallel.ai"

    def __init__(self):
        """Initialize the research lookup tool."""
        if not os.getenv("PARALLEL_API_KEY"):
            raise ValueError(
                "PARALLEL_API_KEY not set. Export it before running:\n"
                "  export PARALLEL_API_KEY='your_parallel_api_key'"
            )

    # ------------------------------------------------------------------
    # Parallel Chat API backend
    # ------------------------------------------------------------------

    def _get_chat_client(self):
        """Lazy-load and cache the OpenAI client for Parallel Chat API."""
        if not hasattr(self, "_chat_client"):
            try:
                from openai import OpenAI
            except ImportError:
                raise ImportError(
                    "The 'openai' package is required for Parallel Chat API.\n"
                    "Install it with: pip install openai"
                )
            self._chat_client = OpenAI(
                api_key=os.getenv("PARALLEL_API_KEY"),
                base_url=self.CHAT_BASE_URL,
            )
        return self._chat_client

    def _parallel_lookup(self, query: str) -> Dict[str, Any]:
        """Run research via the Parallel Chat API (core model)."""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        model = "core"

        try:
            client = self._get_chat_client()

            print(f"[Research] Parallel Chat API (model={model})...", file=sys.stderr)

            response = client.chat.completions.create(
                model=model,
                messages=[
                    {"role": "system", "content": self.PARALLEL_SYSTEM_PROMPT},
                    {"role": "user", "content": query},
                ],
                stream=False,
            )

            content = ""
            if response.choices and len(response.choices) > 0:
                content = response.choices[0].message.content or ""

            api_citations = self._extract_basis_citations(response)
            text_citations = self._extract_citations_from_text(content)

            return {
                "success": True,
                "query": query,
                "response": content,
                "citations": api_citations + text_citations,
                "sources": api_citations,
                "timestamp": timestamp,
                "backend": "parallel",
                "model": f"parallel-chat/{model}",
            }

        except Exception as e:
            return {
                "success": False,
                "query": query,
                "error": str(e),
                "timestamp": timestamp,
                "backend": "parallel",
                "model": f"parallel-chat/{model}",
            }

    def _extract_basis_citations(self, response) -> List[Dict[str, str]]:
        """Extract citation sources from the Chat API research basis."""
        citations = []
        basis = getattr(response, "basis", None)
        if not basis:
            return citations

        seen_urls = set()
        if isinstance(basis, list):
            for item in basis:
                cits = (
                    item.get("citations", []) if isinstance(item, dict)
                    else getattr(item, "citations", None) or []
                )
                for cit in cits:
                    url = cit.get("url", "") if isinstance(cit, dict) else getattr(cit, "url", "")
                    if url and url not in seen_urls:
                        seen_urls.add(url)
                        title = cit.get("title", "") if isinstance(cit, dict) else getattr(cit, "title", "")
                        excerpts = cit.get("excerpts", []) if isinstance(cit, dict) else getattr(cit, "excerpts", [])
                        citations.append({
                            "type": "source",
                            "url": url,
                            "title": title,
                            "excerpts": excerpts,
                        })

        return citations

    # ------------------------------------------------------------------
    # Citation utilities
    # ------------------------------------------------------------------

    def _extract_citations_from_text(self, text: str) -> List[Dict[str, str]]:
        """Extract DOIs and academic URLs from response text as fallback."""
        citations = []

        doi_pattern = r'(?:doi[:\s]*|https?://(?:dx\.)?doi\.org/)(10\.[0-9]{4,}/[^\s\)\]\,\[\<\>]+)'
        doi_matches = re.findall(doi_pattern, text, re.IGNORECASE)
        seen_dois = set()

        for doi in doi_matches:
            doi_clean = doi.strip().rstrip(".,;:)]")
            if doi_clean and doi_clean not in seen_dois:
                seen_dois.add(doi_clean)
                citations.append({
                    "type": "doi",
                    "doi": doi_clean,
                    "url": f"https://doi.org/{doi_clean}",
                })

        url_pattern = (
            r'https?://[^\s\)\]\,\<\>\"\']+(?:arxiv\.org|pubmed|ncbi\.nlm\.nih\.gov|'
            r'nature\.com|science\.org|wiley\.com|springer\.com|ieee\.org|acm\.org)'
            r'[^\s\)\]\,\<\>\"\']*'
        )
        url_matches = re.findall(url_pattern, text, re.IGNORECASE)
        seen_urls = set()

        for url in url_matches:
            url_clean = url.rstrip(".")
            if url_clean not in seen_urls:
                seen_urls.add(url_clean)
                citations.append({"type": "url", "url": url_clean})

        return citations

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def lookup(self, query: str) -> Dict[str, Any]:
        """Perform a research lookup via the Parallel Chat API."""
        print(f"[Research] Query: {query[:80]}...", file=sys.stderr)
        return self._parallel_lookup(query)

    def batch_lookup(self, queries: List[str], delay: float = 1.0) -> List[Dict[str, Any]]:
        """Perform multiple research lookups with delay between requests."""
        results = []
        for i, query in enumerate(queries):
            if i > 0 and delay > 0:
                time.sleep(delay)
            result = self.lookup(query)
            results.append(result)
            print(f"[Research] Completed query {i+1}/{len(queries)}: {query[:50]}...", file=sys.stderr)
        return results


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main():
    """Command-line interface for the research lookup tool."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Research Information Lookup Tool (Parallel Chat API)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Research query (Parallel Chat API, core model)
  python research_lookup.py "latest advances in quantum computing 2025"

  # Batch queries
  python research_lookup.py --batch "query 1" "query 2"

  # Save output to file
  python research_lookup.py "topic" -o results.txt

  # JSON output
  python research_lookup.py "topic" --json -o results.json
        """,
    )
    parser.add_argument("query", nargs="?", help="Research query to look up")
    parser.add_argument("--batch", nargs="+", help="Run multiple queries")
    parser.add_argument("-o", "--output", help="Write output to file")
    parser.add_argument("--json", action="store_true", help="Output as JSON")

    args = parser.parse_args()

    output_file = None
    if args.output:
        output_file = open(args.output, "w", encoding="utf-8")

    def write_output(text):
        if output_file:
            output_file.write(text + "\n")
        else:
            print(text)

    if not os.getenv("PARALLEL_API_KEY"):
        print("Error: PARALLEL_API_KEY not set:", file=sys.stderr)
        print("  export PARALLEL_API_KEY='...'", file=sys.stderr)
        if output_file:
            output_file.close()
        return 1

    if not args.query and not args.batch:
        parser.print_help()
        if output_file:
            output_file.close()
        return 1

    try:
        research = ResearchLookup()

        if args.batch:
            print(f"Running batch research for {len(args.batch)} queries...", file=sys.stderr)
            results = research.batch_lookup(args.batch)
        else:
            print(f"Researching: {args.query}", file=sys.stderr)
            results = [research.lookup(args.query)]

        if args.json:
            write_output(json.dumps(results, indent=2, ensure_ascii=False, default=str))
            if output_file:
                output_file.close()
            return 0

        for i, result in enumerate(results):
            if result["success"]:
                write_output(f"\n{'='*80}")
                write_output(f"Query {i+1}: {result['query']}")
                write_output(f"Timestamp: {result['timestamp']}")
                write_output(f"Backend: {result.get('backend', 'unknown')} | Model: {result.get('model', 'unknown')}")
                write_output(f"{'='*80}")
                write_output(result["response"])

                sources = result.get("sources", [])
                if sources:
                    write_output(f"\nSources ({len(sources)}):")
                    for j, source in enumerate(sources):
                        title = source.get("title", "Untitled")
                        url = source.get("url", "")
                        date = source.get("date", "")
                        date_str = f" ({date})" if date else ""
                        write_output(f"  [{j+1}] {title}{date_str}")
                        if url:
                            write_output(f"      {url}")

                citations = result.get("citations", [])
                text_citations = [c for c in citations if c.get("type") in ("doi", "url")]
                if text_citations:
                    write_output(f"\nAdditional References ({len(text_citations)}):")
                    for j, citation in enumerate(text_citations):
                        if citation.get("type") == "doi":
                            write_output(f"  [{j+1}] DOI: {citation.get('doi', '')} - {citation.get('url', '')}")
                        elif citation.get("type") == "url":
                            write_output(f"  [{j+1}] {citation.get('url', '')}")
            else:
                write_output(f"\nError in query {i+1}: {result['error']}")

        if output_file:
            output_file.close()
        return 0

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        if output_file:
            output_file.close()
        return 1


if __name__ == "__main__":
    sys.exit(main())
