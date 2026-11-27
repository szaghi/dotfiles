---
title: Skills inventory
---

# Skills inventory

Every skill this setup installs, by class (see [Skills](/claude/skills) for what the classes mean and how
`skills-apply` manages them).

## Class A: custom skills in `claude/.claude/skills/`

| Skill | Description (from its `SKILL.md`) |
|---|---|
| `ai-research-verification` | Verification discipline for agent-produced results in computational science: acceptance tests an agent cannot game, claim tiers, triage of 2026 AI-math results |
| `blog` | Write and review technical blog posts as markdown, with the `blog-code-checker` and `blog-prose-reviewer` agents |
| `bug-issue` | Bugs as GitHub issues: investigation, defect, upstream, evidence tiers, test-first fix plan, compiler-bug tracker, see [Bug issues](/claude/bug-issue) |
| `cpp-hpc` | C++ HPC knowledge base: toolchain, modern C++ for performance, OpenMP, MPI, CUDA, Kokkos, I/O, profiling |
| `cuda-programming` | Knowledge base from the CUDA Programming Guide (NVIDIA, Release 13.3) |
| `darktable-operator` | Operator workflow for post-processing a RAW shoot in darktable, with edit values patched into XMP |
| `darktable-raw` | Knowledge base from the darktable 4.6 user manual |
| `delegate` | Hand a mechanical, checkable task to a pi executor (local Ollama or cloud model) in a throwaway git clone, see [Delegating to an executor](/claude/delegate) |
| `fobis` | FoBiS.py expert: fobos files, every `fobis` subcommand, build modes, dependencies |
| `fortran-2023-standard` | Knowledge base from ISO/IEC 1539-1:2023 (Fortran 2023) |
| `gpu-multithreading` | Parallel, multithreaded and GPU programming: design methodology, performance laws, optimisation playbook |
| `hpc-cluster-tooling` | HPC cluster workflow tooling: shell, build systems, debugging, profiling, schedulers |
| `hpc-index` | Router over the HPC skill fleet: which skill to consult when several match |
| `hpc-numerics` | Numerical and algorithmic theory of scientific computing: error, stability, performance models |
| `iso-c-9899-2024` | Knowledge base from ISO/IEC 9899:2024 (C23, draft N3220) |
| `iso-cpp-2023` | Knowledge base from ISO/IEC 14882 (C++23, draft N4950) |
| `llm-wiki` | Consult the compiled knowledge bundles of the llm-wiki repository (a tracked symlink into `~/llm-wiki`) |
| `markdown-mermaid-writing` | Markdown and Mermaid diagrams as the default documentation standard |
| `markitdown` | Convert PDF, Office documents, images, audio, HTML and more to Markdown |
| `mpi-5.0` | Knowledge base from the MPI 5.0 standard |
| `night-protocol` | Unattended-work protocol, see [Night protocol](/claude/night-protocol) |
| `openacc-3.4` | Knowledge base from the OpenACC 3.4 specification |
| `openmp-6.0` | Knowledge base from the OpenMP 6.0 specification with the Nov-2025 errata |
| `plan-issue` | Plans held in a GitHub issue: skeleton, lint, status-table script, see [Plan issues](/claude/plan-issue) |
| `python-conventions` | Stefano's Python conventions: Ruff patterns, pyproject, pytest, typing, docstrings, Makefile, release |
| `python-hpc` | Python performance engineering on CPU and GPU |
| `remotion-infographics` | Still-image infographics and figures for decks, talks and papers with Remotion |
| `research-lookup` | Research lookup through the Parallel Chat API |
| `scientific-writing` | Scientific manuscripts in full paragraphs, outline first, with `research-lookup` |
| `verbatim-edit` | Byte-exact edit protocol: TOML before/after plan, unique match, `sd -F`, build after |

## Class B: plugins in `settings.json`

| Plugin | Marketplace source |
|---|---|
| `frontend-design@claude-plugins-official` | official marketplace |
| `skill-creator@claude-plugins-official` | official marketplace |
| `cli-anything@cli-anything` | `HKUDS/CLI-Anything` |
| `document-skills@anthropic-agent-skills` | `anthropics/skills` (pdf, docx, xlsx, pptx) |
| `ecc@ecc` | `affaan-m/ECC` |

`settings.json` also sets `ECC_DISABLED_HOOKS` to turn off two of the ECC plugin's gateguard hooks.

## Class C: entries in `manifest.toml`

| Entry | What it installs | adam | quark | astrobit |
|---|---|:-:|:-:|:-:|
| `mattpocock-skills` | Matt Pocock's skill bundle (diagnose, tdd, grill-*, …), cloned and linked by its own `link-skills.sh` | yes | | |
| `book-to-skill` | Converts books and documents into skills; clone plus symlink | yes | yes | |
| `pdf-deps` | Python venv `~/.local/share/claude-skills/pdf-venv` for the class-B `pdf` skill | yes | yes | |
| `latex-document-skill` | Community LaTeX skill, clone plus a `latex-venv`; its `setup.sh` is deliberately not run | yes | yes | |
| `remotion-best-practices` | Official Remotion skills via `npx skills add`: ten real sibling directories | yes | yes | |
| `stop-slop` | Removes AI writing tells from prose; clone plus symlink | yes | yes | yes |
