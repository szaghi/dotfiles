---
title: tmux
---

# tmux

The `tmux/` package is a single file, `tmux/.tmux.conf`. It keeps tmux at its defaults (prefix `Ctrl-B`, default key
table) and changes only what matters for long sessions and for Claude Code running inside a pane: mouse, scrollback,
titles and clipboard.

## Install

```bash
bash ~/dotfiles/dotify.sh tmux
```

Reload a running server after editing:

```bash
tmux source-file ~/.tmux.conf
```

## Settings

| Setting | Value | Effect |
|---|---|---|
| `mouse` | `on` | wheel scrolls (enters copy mode), click selects a pane, drag resizes |
| `history-limit` | `50000` | lines of scrollback per pane (tmux default 2000) |
| `set-titles`, `set-titles-string` | `on`, `"#T"` | the pane title goes to the outer terminal's tab |
| `set-clipboard` | `on` | programs in a pane can set the clipboard with OSC 52 |

## Copy bindings

Both the `copy-mode` and `copy-mode-vi` tables get the same bindings.

| Key | Action |
|---|---|
| mouse drag release | copy (tmux buffer and OSC 52) and keep the highlight |
| `Ctrl-C` in copy mode | copy again and leave copy mode |
| `q`, or any key that cancels copy mode | dismiss the selection without copying |
| `Shift` + drag | bypass tmux: the outer terminal's own selection |

## Things to know

- **The titles setting exists for Claude Code.** Claude reports its state in the pane title (spinner while working,
  `✳` when idle); with `set-titles off` the terminal tab never shows it.
- **`Ctrl-C` in copy mode never reaches the pane.** It is bound in the copy-mode tables, so Claude does not read it as
  interrupt or clear-input.
- **OSC 52 needs `set-clipboard on`.** The tmux default (`external`) swallows clipboard writes from programs in the
  pane. `claude-remote` hides `$TMUX` from Claude so that it falls back to raw OSC 52; see [scripts](/packages/scripts).
- **The client needs no tmux.** `claude-remote -H <host>` runs the command on the host over `ssh -t`, so a laptop
  without tmux can still attach to a session living on adam.
