#!/usr/bin/env python3
"""
Example usage of the Research Lookup skill (Parallel Chat API).

This script demonstrates:
1. A single research lookup
2. Batch query processing
3. Integration with scientific writing workflows
"""

import os
from research_lookup import ResearchLookup


def example_single_lookup():
    """Demonstrate a single research lookup."""
    print("=" * 80)
    print("EXAMPLE 1: Single Lookup")
    print("=" * 80)
    print()

    research = ResearchLookup()

    query = "Recent advances in CRISPR gene editing 2024"
    print(f"Query: {query}")
    result = research.lookup(query)
    print(f"Model: {result.get('model')}")
    print(f"Success: {result.get('success')}")
    print(f"Sources: {len(result.get('sources', []))}")
    print()


def example_batch_queries():
    """Demonstrate batch query processing."""
    print("=" * 80)
    print("EXAMPLE 2: Batch Query Processing")
    print("=" * 80)
    print()

    research = ResearchLookup()

    queries = [
        "Recent clinical trials for Alzheimer's disease",
        "Compare deep learning vs traditional ML in drug discovery",
        "Statistical power analysis methods",
    ]

    print("Processing batch queries...")
    print()

    results = research.batch_lookup(queries, delay=1.0)

    for i, result in enumerate(results):
        print(f"Query {i+1}: {result['query'][:50]}...")
        print(f"  Model: {result.get('model')}")
        print(f"  Success: {result.get('success')}")
        print()


def example_scientific_writing_workflow():
    """Demonstrate integration with scientific writing workflow."""
    print("=" * 80)
    print("EXAMPLE 3: Scientific Writing Workflow")
    print("=" * 80)
    print()

    # Literature review phase - breadth
    print("PHASE 1: Literature Review (Breadth)")
    lit_queries = [
        "Recent papers on machine learning in genomics 2024",
        "Clinical applications of AI in radiology",
        "RNA sequencing analysis methods"
    ]

    for query in lit_queries:
        print(f"  - {query}")
    print()

    # Discussion phase - synthesis
    print("PHASE 2: Discussion (Synthesis & Analysis)")
    discussion_queries = [
        "Compare the advantages and limitations of different ML approaches in genomics",
        "Explain the relationship between model interpretability and clinical adoption",
        "Analyze the ethical implications of AI in medical diagnosis"
    ]

    for query in discussion_queries:
        print(f"  - {query}")
    print()


def main():
    """Run all examples (requires PARALLEL_API_KEY to be set)."""

    if not os.getenv("PARALLEL_API_KEY"):
        print("Note: Set PARALLEL_API_KEY environment variable to run live queries")
        print("These examples show the structure without making actual API calls")
        print()

    # Uncomment to run examples (requires API key)
    # example_single_lookup()
    # example_batch_queries()

    # Workflow outline (no API calls)
    example_scientific_writing_workflow()


if __name__ == "__main__":
    main()
