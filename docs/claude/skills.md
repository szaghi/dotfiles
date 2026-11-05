---
title: Skills
---

# Skills

Skills reach `~/.claude/skills/` from three owners with different lifecycles: git and stow for the skills
written here, the `claude plugin` CLI for marketplace plugins, and upstream installers for third-party skills.
`skills-apply` (`scripts/.scripts/skills-apply`) drives the last two from declarations in the repo, so a fresh
host gets the same set with one command. Design notes: `claude/.claude/skills/README.md`.

## The three classes

| Class | Owner | Declared in | In `~/.claude/skills/` |
|---|---|---|---|
| **A** custom | git + stow | `claude/.claude/skills/<name>/` | symlink into the repo |
| **B** plugin | `claude plugin` CLI | `settings.json` → `enabledPlugins` (marketplaces in `extraKnownMarketplaces`) | nothing; loaded from `~/.claude/plugins/cache/` |
| **C** third-party | upstream installer | `claude/.claude/skills/manifest.toml` | a symlink to a clone, or real directories, depending on the installer |

Class A stows everywhere. Class B is the same on every host, since `settings.json` is shared. Class C is
filtered per host by `machines/<hostname>.skills`: one name per line, blank lines and `#` comments ignored. A
missing file means every manifest entry, so a new host opts out rather than in.

## skills-apply

```bash
skills-apply install        # install everything declared; idempotent
skills-apply update         # update every installed plugin and class-C skill
skills-apply status         # installed vs declared, for all three classes
skills-apply remove <name>  # uninstall one plugin or class-C skill (alias: uninstall)
```

| Command | Class B | Class C |
|---|---|---|
| `install` | `claude plugin install <p>` unless `claude plugin list` already has it | runs `install` unless `check` exits 0 |
| `update` | `claude plugin update <p>`; a failure warns and continues | runs `update`; warns and skips an entry whose `check` fails |
| `status` | `!` for an enabled plugin not installed | `!` for an entry whose `check` fails |
| `remove` | `claude plugin uninstall` | runs `uninstall` |

Restart Claude Code after `install` or `update`, so plugin changes load. `status` always exits 0: it is a
report, not a gate. It needs `python3` 3.11+ (`tomllib`, or `tomli` on older Python) and the `claude` CLI, and
exits 2 when either is missing.

## Adding a skill

**Class A.** Create the directory with at least a `SKILL.md`, commit it, re-stow:

```bash
mkdir -p ~/dotfiles/claude/.claude/skills/<name>
$EDITOR ~/dotfiles/claude/.claude/skills/<name>/SKILL.md
cd ~/dotfiles && git add claude/.claude/skills/<name>/
bash ~/dotfiles/dotify.sh claude
```

**Class B.** Install once, then commit the `enabledPlugins` entry Claude Code added. Other hosts get it from
`skills-apply install`.

```bash
claude plugin install <name>@<marketplace>
cd ~/dotfiles && git diff claude/.claude/settings.json
```

**Class C.** Add an entry to `manifest.toml` and the name to each `machines/<host>.skills` that should get it.
The repo owns the recipe; the upstream tool does the work, so never vendor an installer.

```toml
[skills.<name>]
description = "one line, shown by skills-apply status"
check       = "test -L ~/.claude/skills/<name> && test -d ~/.local/share/claude-skills/<name>/.git"
install     = "{ test -d ~/.local/share/claude-skills/<name>/.git || git clone --depth 1 <url> ~/.local/share/claude-skills/<name>; } && ln -sfn ~/.local/share/claude-skills/<name> ~/.claude/skills/<name>"
update      = "git -C ~/.local/share/claude-skills/<name> pull --ff-only"
uninstall   = "rm -f ~/.claude/skills/<name>; rm -rf ~/.local/share/claude-skills/<name>"
```

Two rules keep an entry repairable after a partial install:

- `check` tests every piece the install produces. A `check` that tests only the clone reports "already
  installed" while the symlink is missing, and `install` never runs again.
- `install` is idempotent, because it is what runs when `check` fails. A bare `git clone` aborts on an existing
  directory and never reaches the `ln -sfn`; guard it as above.

## Drift signals

`skills-apply status` marks drift with `!` and never fixes it:

| Message | Meaning |
|---|---|
| `<name> (outside dotfiles — not yet migrated?)` | A directory in `~/.claude/skills/` that resolves outside the repo and belongs to no plugin or manifest entry |
| `<name> (in dotfiles but SKILL.md not tracked by git)` | A skill in the repo you forgot to `git add`, or an empty directory left by a tool |
| `<plugin> (declared but not installed — run skills-apply install)` | Enabled in `settings.json`, absent on this host |
| `<name> (declared but not installed)` | A class-C entry whose `check` fails |

A real directory in `~/.claude/skills/` is the usual drift signal: a class-A skill not yet moved into the repo,
or a stale copy. Expected exceptions are the installers that write real directories (the Remotion entry) and
`synced/`.

`remove` does not edit the declarations. It prints which file to edit (`enabledPlugins` in `settings.json` or
`[skills.<name>]` in `manifest.toml`); without that edit the next `install` brings the skill back. A class-A skill
is removed by deleting its directory from the repo and re-stowing.

## Exporting the HPC skills

`export-public-skills.sh` (repo root) copies an allowlist of class-A skills into the working tree of the public
`claude-skills-hpc` repository, at `$CLAUDE_SKILLS_HPC_REPO` (default `~/claude/claude-skills-hpc`), under
`skills/<name>`.

```bash
bash ~/dotfiles/export-public-skills.sh --dry-run   # list what would be exported (also -n)
bash ~/dotfiles/export-public-skills.sh
```

- Only the 13 skills in its `ALLOWLIST` are exported: the seven standard and spec references, `cpp-hpc`,
  `python-hpc`, `gpu-multithreading`, `hpc-numerics`, `hpc-cluster-tooling`, `hpc-index`. Anything else cannot
  leak through it.
- Each export replaces the destination copy (`rm -rf`, then `cp -RL`), so deletions propagate; nested `.git`
  directories are dropped.
- It never runs `git add`, `commit` or `push`: review and publish the target repo by hand.
- It stops if the target repo does not exist.

## Inventory

### Class A: custom skills in `claude/.claude/skills/`

| Skill | Description (from its `SKILL.md`) |
|---|---|
| `ai-research-verification` | Verification discipline for agent-produced results in computational science: acceptance tests an agent cannot game, claim tiers, triage of 2026 AI-math results |
| `blog` | Write and review technical blog posts as markdown, with the `blog-code-checker` and `blog-prose-reviewer` agents |
| `cpp-hpc` | C++ HPC knowledge base: toolchain, modern C++ for performance, OpenMP, MPI, CUDA, Kokkos, I/O, profiling |
| `cuda-programming` | Knowledge base from the CUDA Programming Guide (NVIDIA, Release 13.3) |
| `darktable-operator` | Operator workflow for post-processing a RAW shoot in darktable, with edit values patched into XMP |
| `darktable-raw` | Knowledge base from the darktable 4.6 user manual |
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
| `python-conventions` | Stefano's Python conventions: Ruff patterns, pyproject, pytest, typing, docstrings, Makefile, release |
| `python-hpc` | Python performance engineering on CPU and GPU |
| `remotion-infographics` | Still-image infographics and figures for decks, talks and papers with Remotion |
| `research-lookup` | Research lookup through the Parallel Chat API |
| `scientific-writing` | Scientific manuscripts in full paragraphs, outline first, with `research-lookup` |
| `verbatim-edit` | Byte-exact edit protocol: TOML before/after plan, unique match, `sd -F`, build after |

### Class B: plugins in `settings.json`

| Plugin | Marketplace source |
|---|---|
| `frontend-design@claude-plugins-official` | official marketplace |
| `skill-creator@claude-plugins-official` | official marketplace |
| `cli-anything@cli-anything` | `HKUDS/CLI-Anything` |
| `document-skills@anthropic-agent-skills` | `anthropics/skills` (pdf, docx, xlsx, pptx) |
| `ecc@ecc` | `affaan-m/ECC` |

`settings.json` also sets `ECC_DISABLED_HOOKS` to turn off two of the ECC plugin's gateguard hooks.

### Class C: entries in `manifest.toml`

| Entry | What it installs | adam | quark | astrobit |
|---|---|:-:|:-:|:-:|
| `mattpocock-skills` | Matt Pocock's skill bundle (diagnose, tdd, grill-*, …), cloned and linked by its own `link-skills.sh` | yes | | |
| `book-to-skill` | Converts books and documents into skills; clone plus symlink | yes | yes | |
| `pdf-deps` | Python venv `~/.local/share/claude-skills/pdf-venv` for the class-B `pdf` skill | yes | yes | |
| `latex-document-skill` | Community LaTeX skill, clone plus a `latex-venv`; its `setup.sh` is deliberately not run | yes | yes | |
| `remotion-best-practices` | Official Remotion skills via `npx skills add`: ten real sibling directories | yes | yes | |
| `stop-slop` | Removes AI writing tells from prose; clone plus symlink | yes | yes | yes |

## Things to know

- Bundles show their members under class A in `status` (`diagnose`, `tdd`, `remotion-captions`, …), because
  `skills-apply` keys class C by entry name. Cosmetic, not drift.
- `~/.claude/skills/synced/` is written by Claude Code itself: the skills provisioned to each claude.ai account,
  one bucket per account. It is gitignored, skipped by `status`, and must not be deleted.
- `latex-document-skill`'s `setup.sh` runs `pip install --break-system-packages`; the manifest builds a venv from
  its `requirements.txt` instead.
- A class-C `.venv` built inside a stowed skill directory lands in the repo; `.gitignore` excludes
  `claude/.claude/skills/*/.venv/`.
