# Claude Code Skills — Dotfiles Layout

Three structurally different classes of skill end up in `~/.claude/skills/`;
each has its own lifecycle owner. This directory plus the `skills-apply`
script (`scripts/.scripts/skills-apply`) wire all three into one
declarative, per-host workflow.

## The three classes at a glance

| Class | Lifecycle owner | Declared in | On-disk shape in `~/.claude/skills/` |
|---|---|---|---|
| **A. Custom user-authored** | git + stow | `claude/.claude/skills/<name>/` (real source dirs in this repo) | symlink → repo |
| **B. Plugin / marketplace** | `claude plugin` CLI | `claude/.claude/settings.json` → `enabledPlugins` | (none — claude loads them from `~/.claude/plugins/cache/`) |
| **C. Third-party loose** | upstream installer (pipx / venv / `curl \| bash` / `uv tool install`) | `claude/.claude/skills/manifest.toml` | varies — sometimes a real dir, sometimes nothing (binary on `$PATH`) |

### A. Custom user-authored skills

Plain source directories that live **inside this directory** and ship via
stow. They have no installer — git tracks the source, stow deploys symlinks
into `~/.claude/skills/`.

Add one:

```bash
# 1. drop the skill into the repo (SKILL.md at minimum)
mkdir -p ~/dotfiles/claude/.claude/skills/<name>
cp -a /path/to/SKILL.md ~/dotfiles/claude/.claude/skills/<name>/

# 2. version it
cd ~/dotfiles && git add claude/.claude/skills/<name>/

# 3. deploy as symlink
bash ~/dotfiles/dotify.sh claude
```

The new symlink at `~/.claude/skills/<name>/` is immediate; Claude Code
picks it up on its next session.

### B. Plugin / marketplace skills

Installed and updated by Claude Code's own `claude plugin` CLI. The desired
set is declared in `../settings.json` under `enabledPlugins` (with
marketplaces under `extraKnownMarketplaces`). On a fresh machine
`skills-apply install` invokes `claude plugin install <name>@<marketplace>`
for each enabled entry; on an existing machine `skills-apply update` runs
`claude plugin update <name>` for each.

Add one:

```bash
# 1. install once on any host
claude plugin install <name>@<marketplace>

# 2. confirm settings.json was updated by Claude Code, commit it
cd ~/dotfiles && git diff claude/.claude/settings.json   # should show new enabledPlugins entry
git add claude/.claude/settings.json && git commit
```

Other hosts pick it up on their next `skills-apply install`.

### C. Third-party loose skills

Skills with their own installers (binaries, PyPI packages, bundled venvs).
Declared in `manifest.toml` with `check` / `install` / `update` /
`uninstall` shell commands. `skills-apply` reads the manifest and invokes
the upstream installer — dotfiles own the *recipe*, the upstream tool owns
the *work*. Never vendor an installer; wrap it.

Add one:

```toml
# manifest.toml
[skills.<name>]
description = "one-line summary shown by skills-apply status"
check       = "command -v <name>"          # exits 0 iff already installed
install     = "uv tool install <pypi-pkg>" # or pipx, curl|bash, etc.
update      = "uv tool upgrade <pypi-pkg>"
uninstall   = "uv tool uninstall <pypi-pkg>"
```

Then add the skill name to each `machines/<host>.skills` that should sync
it (omit on hosts that should skip it).

## Per-host profiles (`machines/<hostname>.skills`)

Class C skills are filtered per host by `~/dotfiles/machines/<hostname>.skills`:
one skill name per line; blank lines and `#` comments allowed. A missing
file means "install every manifest entry on this host" — keep that
convention as the default so new hosts opt-out rather than opt-in.

```text
# machines/adam.skills      (WSL2 workstation — full set)
perplexity-search
mattpocock-skills
book-to-skill
pdf-deps
latex-document-skill
stop-slop

# machines/quark.skills     (Chuwi N150 laptop — no mattpocock bundle)
perplexity-search
book-to-skill
pdf-deps
latex-document-skill
stop-slop

# machines/cluster.skills   (HPC login node)
# (intentionally empty: no class-C skills make sense on a shared cluster)
```

Class A skills always stow everywhere (cheap, source-only). Class B skills
are host-uniform via `settings.json`.

## `skills-apply` interface

```bash
skills-apply install          # install everything declared (idempotent)
skills-apply update           # update every installed skill
skills-apply status           # show installed-vs-declared for all classes
skills-apply remove <name>    # uninstall one skill (plugin or manifest)
```

`install` is safe to re-run — every entry has a `check` (class C) or a
`claude plugin list` membership test (class B) before running its install
command.

`status` exits 0 even when skills are missing — it is a report, not a
gate. Pipe to grep if you need to alert in CI.

`remove` runs the uninstall but does **not** rewrite `settings.json` or
`manifest.toml` — it prints a warning telling you to edit the declaration
file by hand. This is deliberate: the script never silently mutates your
declarations.

Restart Claude Code after `install` or `update` so plugin changes load
(the `claude plugin update` CLI itself says "restart required to apply").

## What's in this repo today

Inventory of skills currently shipped via this directory and `manifest.toml`:

| Skill | Class | Notes |
|---|---|---|
| `fobis/` | A | `/fobis` slash command — FoBiS.py build tool expert |
| `generate-image/` | A | FLUX / Nano Banana image generation |
| `markdown-mermaid-writing/` | A | Markdown + Mermaid diagram authoring |
| `markitdown/` | A | Convert PDF / DOCX / PPTX / etc. to Markdown |
| `research-lookup/` | A | Parallel Chat API + Perplexity research backend |
| `scientific-writing/` | A | IMRAD manuscript / reporting-guideline workflow |
| `darktable-raw/` | A | darktable 4.6 manual as a knowledge base (modules, scene-referred pipeline, darktable-cli) |
| `darktable-operator/` | A | RAW post-processing workflow — Claude drives darktable-cli; prompt-controlled edit values via XMP patching (see its `USER-GUIDE.md`) |
| `frontend-design@claude-plugins-official` | B | Distinctive frontend interfaces |
| `skill-creator@claude-plugins-official` | B | Create / evaluate / optimize skills |
| `cli-anything@cli-anything` | B | CLI-Anything plugin (HKUDS/CLI-Anything) |
| `document-skills@anthropic-agent-skills` | B | Official Anthropic pdf / xlsx / docx / pptx skills (Python deps via `pdf-deps` venv) |
| `perplexity-search` | C | `.venv` + `litellm` — Perplexity search via OpenRouter |
| `mattpocock-skills` | C | Matt Pocock skill bundle (diagnose, tdd, grill-*, …) — host: adam only |
| `book-to-skill` | C | Convert books / documents into structured skills |
| `pdf-deps` | C | Isolated venv (pypdf, pdfplumber, reportlab, …) backing the class-B `pdf` skill |
| `latex-document-skill` | C | Community LaTeX skill — XeLaTeX/LuaLaTeX auto-detect, latexmk backend, isolated venv |
| `stop-slop` | C | Remove AI writing tells from prose (static markdown, no build) |

### HPC skill fleet

A coherent set of class-A knowledge skills covering high-performance and
scientific computing, structured on a **reference vs applied vs theory vs
workflow** axis. Each (except the router) is a `SKILL.md` plus chapter files
under `chapters/` and a `cheatsheet.md` / `glossary.md` / `patterns.md`. They
are the skills exported to the public `claude-skills-hpc` repository by
`../../../export-public-skills.sh` (see its `ALLOWLIST`).

| Skill | Layer | Notes |
|---|---|---|
| `iso-c-9899-2024/` | reference (standard) | ISO/IEC 9899:2024 — C23 (working draft N3220) |
| `iso-cpp-2023/` | reference (standard) | ISO/IEC 14882 — C++23 (working draft N4950) |
| `fortran-2023-standard/` | reference (standard) | ISO/IEC 1539-1:2023 — Fortran 2023 |
| `mpi-5.0/` | reference (spec) | MPI 5.0 — message passing, collectives, RMA, MPI-IO |
| `openmp-6.0/` | reference (spec) | OpenMP API v6.0 (+ Nov-2025 errata) |
| `openacc-3.4/` | reference (spec) | OpenACC API v3.4 |
| `cuda-programming/` | reference (spec) | CUDA Programming Guide (NVIDIA, Release 13.3) |
| `cpp-hpc/` | applied | C++ HPC toolchain, idioms, parallel models, ecosystem |
| `python-hpc/` | applied | Python CPU + GPU performance engineering |
| `gpu-multithreading/` | applied | Cross-language parallel design + optimization playbook |
| `hpc-numerics/` | theory | Numerical algorithms, error/stability, roofline |
| `hpc-cluster-tooling/` | workflow | SLURM, Make/CMake, GDB/sanitizers, perf/TAU |
| `hpc-index/` | router | Disambiguation map over the twelve skills above (holds no domain knowledge) |

## Dependencies

- `claude` — the Claude Code CLI binary (used by `skills-apply` for class B).
- `python3` 3.11+ — `skills-apply` uses inline `tomllib` to parse this
  manifest and `json` to parse `settings.json`. Older Python works only if
  `tomli` is pip-installed as a fallback.
- The per-skill install commands declare their own dependencies (e.g.
  perplexity-search needs system `python3` with `venv` support).

## When something looks wrong

`skills-apply status` flags drift visibly with `!`:

- **`!  <name>  (not a symlink — not yet migrated into dotfiles?)`** —
  a real directory exists at `~/.claude/skills/<name>/` that is not in
  this repo. Either migrate it (`cp -a` into `claude/.claude/skills/`,
  `rm -rf` the original, re-stow) or delete it if unwanted.
- **`!  <plugin>  (declared but not installed — run skills-apply install)`** —
  the plugin is in `enabledPlugins` but Claude Code has not installed it
  on this host yet. Run `skills-apply install`.
- **`!  <name>  (declared but not installed)`** (class C) — manifest entry's
  `check` command returned non-zero. Run `skills-apply install`.

Drift cannot be auto-fixed silently — the script makes you see it, you
decide.
