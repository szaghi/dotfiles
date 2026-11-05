---
title: Python and LaTeX
---

# Python and LaTeX

Two small packages of single-file configs. `python/` holds the interactive interpreter's startup script and a pylint
configuration; `miscellanea/` holds the latexmk configuration and a NAS mount script that is not stowed.

## Install

```bash
bash ~/dotfiles/dotify.sh python miscellanea
```

| File | Linked to |
|---|---|
| `python/.pythonrc` | `~/.pythonrc` |
| `python/.pylintrc` | `~/.pylintrc` |
| `miscellanea/.latexmkrc` | `~/.latexmkrc` |
| `miscellanea/mount-zaghi-nas.sh` | not linked: excluded by `miscellanea/.stow-local-ignore` |

## `.pythonrc`

The interpreter runs it at start because `bash/.bash/exports` sets `PYTHONSTARTUP=$HOME/.pythonrc`. It applies only
to the interactive `python` prompt, not to scripts.

| Feature | Detail |
|---|---|
| Prompt | green `>>>`, red `...` |
| Completion | jedi's readline completion if `jedi` is importable; otherwise `rlcompleter` on `Tab` (it prints "No jedi here. Coming to the dark side.") |
| History | read from and written to `~/.python_history`, unlimited length; disabled with `NOHIST` in the environment |
| Display hook | results are pretty-printed to the terminal width and stored in `_`; functions and modules print their docstring |
| `source(obj)` | shows the source of `obj` in the pager |
| Import safety | the current directory is removed from `sys.path` while the script runs, so a local module cannot shadow its imports |

```bash
NOHIST=1 python3      # a session that leaves no history
```

## `.pylintrc`

| Section | Setting |
|---|---|
| `[MESSAGES CONTROL]` | disables, among others, missing docstrings (`C0111`), line too long (`C0301`), invalid name (`C0103`), too many arguments (`R0913`) and too many locals (`R0914`) |
| `[FORMAT]` | `max-line-length=500`, `indent-string='  '` (two spaces) |
| `[MASTER]` | `jobs=4` |
| `[DESIGN]` | `max-args=10`, `max-locals=15`, `max-branches=12`, `max-statements=50` |

## `.latexmkrc`

It sets latexmk's `$pdflatex` to XeLaTeX with SyncTeX:

```perl
$pdflatex = 'xelatex -synctex=1 %O %S';
```

Together with the `latexmk` alias (`latexmk -pdf`, from [bash](/packages/bash)), a plain `latexmk main.tex` builds the
PDF with XeLaTeX.

## `mount-zaghi-nas.sh`

Mounts the home NAS share over NFS on `/media/stefano/zaghi-nas/` with `sudo`. The NAS address defaults to a value in
the script and is overridden with `NAS_ZAGHI_IP`. It is not on `PATH`; run it from the repository.

## Things to know

- **`.pythonrc` is Python 2 code that half-works on Python 3.**
  - Echoing a function at the prompt raises `AttributeError: module 'inspect' has no attribute 'formatargspec'`:
    `formatargspec` is gone from Python 3.11 and later, and the hook only catches `TypeError`. Use `help(f)`
    instead.
  - The Pygments colouring of results and tracebacks never activates: it imports `cStringIO`, which does not exist
    in Python 3, and falls back to plain `pprint`.
  - The docstring at the top says history goes to `~/.history/python`; the code writes `~/.python_history`.
- **`.pylintrc` is legacy.** The vim setup lints Python with ruff through ALE (`vim/.vim/plugconf/ale.vim`), not
  pylint. Its two-space `indent-string` contradicts the four-space Python indentation used
  everywhere else.
- **`.latexmkrc` assigns `$pdflatex` twice.** The second line wins, so the first line's `--shell-escape` is not in
  effect. Packages that need shell escape (`minted`, for instance) fail unless the flag is added to the last line.
