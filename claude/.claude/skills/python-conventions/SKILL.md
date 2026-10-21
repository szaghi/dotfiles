---
name: python-conventions
description: Stefano's Python conventions - Ruff first-pass patterns (B904 exception chaining, B905 zip strict, S608, RUF002, C408), pyproject-only packaging, pytest layout, full type annotations, NumPy/Google docstrings, logging, .venv, the standard Makefile, git-cliff changelog and the release.sh workflow. Use before writing, editing or reviewing any Python code or pyproject.toml, and when creating a Python project, Makefile or release script.
---

# Python Conventions

Reference repos: `~/python/FoBiS/`, `~/python/mosaic/`, `~/python/MaTiSSe/` — verify paths exist before using them.

**Tooling:**
- Linter/formatter: **Ruff** — follow per-project `pyproject.toml` for rule selection and line length
- Package management: **pyproject.toml** (no setup.py, no setup.cfg)
- Testing: **pytest** with coverage reporting; tests live in `/tests/`

**Ruff patterns — write correctly on first pass, never wait for lint to catch these:**

- **B904** — always chain exceptions inside `except` blocks:
  ```python
  # WRONG
  except SomeError:
      raise typer.Exit(1)
  # CORRECT — from None for control-flow exits, from err for re-raises
  except SomeError as e:
      raise typer.Exit(1) from None
  except SomeError as e:
      raise MyError("...") from e
  ```
- **B905** — always pass `strict=` to `zip()`:
  ```python
  zip(xs, ys, strict=True)   # lengths must match
  zip(xs, ys, strict=False)  # truncation is intentional
  ```
- **S608** — dynamic `IN (?)` SQL built from `"?" * len(xs)` is safe but ruff flags it; suppress with `# noqa: S608`
- **RUF002** — no Unicode math symbols (`×`, `·`) in docstrings; use ASCII (`*`, `.`)
- **C408** — use dict literals, not `dict()` calls: `{"k": v}` not `dict(k=v)`

**Type annotations:**
- Always fully annotated — use `from __future__ import annotations` in every source file
- Full return type hints; use PEP 604 union syntax (`str | None`, not `Optional[str]`)

**Docstrings:**
- Default: **NumPy-style** (`Parameters`, `Returns`, `Raises` sections) — matches scientific Python ecosystem
- Exception: **Google-style** for non-scientific application code (CLI tools, web apps, etc.)

**Logging:**
- Use `log = logging.getLogger(__name__)` — no print statements in library code

**Virtual environment:**
- Always use `.venv` for project-specific environments: `python -m venv .venv && source .venv/bin/activate`
- WSL2 system Python is externally managed — direct `pip install` without a venv will fail
- Activate `.venv` before running any Python command; never assume the system Python is usable

**Makefile — standard dev interface:**
All Python projects use a Makefile as the standard interface for development tasks. Always invoke tools from `$(VENV)/bin/` — never rely on system PATH resolution.

```makefile
.PHONY: dev test lint fmt clean

VENV   := .venv
PYTHON := $(VENV)/bin/python
PIP    := $(VENV)/bin/pip

$(VENV)/bin/activate:
	python3 -m venv $(VENV)

## Install package in editable mode with dev extras
dev: $(VENV)/bin/activate
	$(PIP) install -e ".[dev]"

## Run test suite
test: dev
	$(VENV)/bin/pytest

## Check linting and formatting (no fixes)
lint: dev
	$(VENV)/bin/ruff check .
	$(VENV)/bin/ruff format --check .

## Auto-fix lint issues and apply formatting
fmt: dev
	$(VENV)/bin/ruff check --fix .
	$(VENV)/bin/ruff format .

## Remove build artifacts
clean:
	rm -rf dist/ build/ *.egg-info .pytest_cache .ruff_cache .coverage coverage.xml
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null; true
```

Rules:
- `lint` is read-only (check only); `fmt` is destructive (auto-fix) — keep them separate
- `test` depends on `dev` — ensures the env is always up-to-date before running tests
- `clean` removes all nested `__pycache__/` dirs via `find` — `rm -rf __pycache__/` only removes the root-level one

**Changelog:**
- Use `git-cliff` for changelog generation, driven by Conventional Commits
- Preview unreleased: `git cliff --unreleased`; regenerate: `git cliff -o CHANGELOG.md`
- For full release workflow (branch model, tagging, CI publish) see **Release workflow** below

**Testing conventions:**
- Mock all external I/O in unit tests: HTTP calls, filesystem access, subprocess — no real network requests
- Use `conftest.py` for shared fixtures and test helpers
- If the test suite requires an external tool (compiler, binary, service), document it explicitly in the project CLAUDE.md

**Exception design:**
- Define a project-level exception hierarchy: `ProjectError` → specific subclasses (`SourceError`, `BuildError`, etc.)
- Never raise bare `Exception` or `BaseException`; always raise a typed, meaningful exception

**Release workflow (`release.sh`):**

Standard invocation:
```bash
./release.sh --major | --minor | --patch | X.Y.Z
```

Pre-flight checks (always, in this order):
1. Working tree is clean — no uncommitted changes
2. On the correct branch (`develop` for GitFlow, `master`/`main` for trunk)
3. Local branches up-to-date with remote — fail fast if behind
4. `git fetch --tags` — verify tag does not already exist
5. `git-cliff` available
6. **Lint must pass before any branch is created** — run `ruff check` + `ruff format --check`; abort with "run `make fmt` to fix"

Version bump:
- `pyproject.toml` is the canonical version source; `package/__init__.py` is a mirror
- Always update **both** with `sed`; verify each replacement with `grep` immediately after

Changelog:
```bash
git-cliff --tag "vX.Y.Z" -o docs/guide/changelog.md   # VitePress docs
# Mirror to root CHANGELOG.md if needed:
{ printf -- "---\ntitle: Changelog\n---\n\n"; awk '/^## \[/{found=1} found' docs/guide/changelog.md; } > CHANGELOG.md
```

Commit and tag conventions:
```bash
git commit -m "chore(release): bump version to vX.Y.Z"
git tag -a "vX.Y.Z" -m "Release vX.Y.Z"    # always annotated
```

PyPI publish: **never locally** — always triggered by tag push via CI:
```bash
git push origin master          # or main
git push origin "vX.Y.Z"        # triggers CI → PyPI
```

Branch models — two patterns in use:
- **GitFlow** (FoBiS): `develop` → `release/vX.Y.Z` → merge to `master` (no-ff) → tag → push → merge back to `develop` → delete release branch
- **Trunk** (mosaic, MaTiSSe): stay on `master`/`main`, commit version bump, tag, `git push --follow-tags`

Error recovery: use stage tracking + `trap ERR` with per-stage recovery instructions (MaTiSSE pattern). Each stage sets a `STAGE` variable; the trap prints exact git commands to resume from that point.
