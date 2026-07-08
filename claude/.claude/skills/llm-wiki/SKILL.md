---
name: llm-wiki
description: Consult Stefano's compiled OKF knowledge bundles at ~/llm-wiki (the "second brain"). TRIGGER whenever a question falls in an existing bundle's domain — currently div-free-amr; numerical divergence constraints (∇·B=0, incompressibility), constrained transport and flux-CT, projection/divergence-cleaning, eight-wave, staggered vs collocated grids, discrete divergence/curl operators, SBP, mimetic/compatible/structure-preserving discretizations, DEC, block-structured AMR refinement interfaces, prolongation/restriction commutation. Also trigger on explicit mentions: "llm-wiki", "second brain", "check the wiki", "what does the wiki say". Use for CONSULTATION from any directory; ingestion/compilation work happens in ~/llm-wiki under its own CLAUDE.md.
---

# Consulting the LLM wiki

The bundles live at `~/llm-wiki/<bundle>/wiki/` (OKF v0.1: markdown + YAML
frontmatter). Current bundles: `div-free-amr`.

## Protocol

1. **Enter at the catalog.** Read `~/llm-wiki/<bundle>/wiki/index.md`, follow
   links; navigation is the query engine. For symbol/term lookups, Grep the
   bundle (tags in frontmatter, math symbols like `$P_D$`, aliases).
2. **Notation is registry-defined.** `wiki/notation.md` is normative; when
   quoting wiki math, keep its symbols. Per-paper symbol translations are in
   each Source page's `# Notation map`.
3. **Respect claim kind.** Frontmatter `status: established` = published
   result; `status: hypothesis` = claim a published source could overturn —
   report it as such, never as literature fact.
4. **Cite pages.** Answers grounded in the wiki cite the concept page(s) and,
   for provenance, the Source pages they rest on (`wiki/sources/*.md`, which
   carry DOIs and local PDF paths for going deeper).
5. **Coverage is partial.** Compilation is incremental — check
   `~/llm-wiki/tools/worklist.sh <bundle>` (or `wiki/log.md`) before treating
   absence of a page as absence of literature. If the wiki lacks the answer,
   say so explicitly and fall back to the PDFs or general knowledge, labeled
   as such.
6. **Read-only from outside.** Never edit bundle content from another
   project's session. Gaps worth compiling: suggest an ingestion, to be run
   in `~/llm-wiki` under its constitution (`~/llm-wiki/CLAUDE.md`).
