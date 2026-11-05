---
title: Per-host packages
---

# Per-host packages

Some configuration is true for one machine only: a GPG signing key, the GPU an LLM server may use, the model that
fits in RAM. It lives in packages named after the host, which `dotify.sh` stows only on that host. Everything shared
stays in the common packages. The machines themselves are described in [The machines](/guide/machines).

## How a host picks its packages

`dotify.sh` stows the common packages, then reads `machines/$(hostname -s)` and stows every package listed there, one
per line; blank lines and `#` comments are skipped.

```bash
bash ~/dotfiles/dotify.sh            # common packages + this host's list
bash ~/dotfiles/dotify.sh --dry-run  # preview
```

| Host | `machines/<host>` lists |
|---|---|
| adam | `usr`, `bash-adam` |
| quark | `bash-quark`, `desktop` |
| astrobit | `bash-astrobit`, `desktop-astrobit` |

The desktops have their own pages: [quark desktop](/packages/desktop-quark) and
[astrobit desktop](/packages/desktop-astrobit).

## `bash-<host>`

Each one carries two files.

| File | Linked to | Overrides |
|---|---|---|
| `bash-<host>/.bash/claude_code.local` | `~/.bash/claude_code.local` | values of `bash/.bash/claude_code`, which sources this file at its end |
| `bash-<host>/.gitconfig.local` | `~/.gitconfig.local` | `user.signingkey`, read through the `[include]` in `git/.gitconfig` |

What each host's `claude_code.local` sets:

| Host | Settings |
|---|---|
| adam | account e-mails for the `claude-<acct>` login prompt; GPU UUID and id for Ollama; flash attention and `q8_0` KV cache; Ollama default, light, plan and exec models; the locally CUDA-built `llama-server` and `ik_llama.cpp` binaries with their CUDA runtime libraries; default GGUF models; ik_llama context 32768 |
| quark | small Ollama models for 16 GB of RAM; llama.cpp CPU-only (`LLAMACPP_GPU_LAYERS=0`), context 8192 |
| astrobit | the smallest Ollama models; `OLLAMA_KEEP_ALIVE=2m` so idle models leave RAM to the telescope stack; llama.cpp CPU-only, context 4096 |

How these variables are used: [Local LLM servers](/claude/local-llm) and [Accounts and providers](/claude/wrappers).
Signing itself: [git](/packages/git).

## `usr/`

Desktop entries in `usr/.local/share/applications/`, with their icons, for programs installed by hand under `/opt`:
Bitwarden, Blender, ChituBox, CURA, FreeCAD, Ideamaker, Lychee, OrcaSlicer, ParaView, SuperSlicer, Telegram,
UVTools. `claude-code-url-handler.desktop` registers `claude --handle-uri` for `claude-cli://` links. Only adam
stows `usr`.

## `machines/<host>.skills`

One Claude Code skill name per line: the class-C (manifest) skills that `skills-apply install` installs on that host.
A missing file means every manifest entry. Details: [Skills](/claude/skills).

| File | Skills |
|---|---|
| `machines/adam.skills` | `mattpocock-skills`, `book-to-skill`, `pdf-deps`, `latex-document-skill`, `stop-slop`, `remotion-best-practices` |
| `machines/quark.skills` | `book-to-skill`, `pdf-deps`, `latex-document-skill`, `stop-slop`, `remotion-best-practices` |
| `machines/astrobit.skills` | `stop-slop` |

## Not stow packages

| Directory | What it is |
|---|---|
| `machines/` | the host lists above |
| `background/` | wallpaper images; referenced by nothing in the repository |
| `screenshots/` | images of the prompt, its git status and a desktop preview; referenced by nothing in the repository |
| `bin/` | empty and untracked; the standalone binaries live in `scripts/.bin`, see [scripts](/packages/scripts) |

`dotify.sh` stows only the names in its `PACKAGES` list and in `machines/<host>`, so these directories are never
linked.

## Things to know

- **The host list is keyed on `hostname -s`.** A machine with a different short hostname gets the common packages
  only, without error.
- **A new host needs its own key.** Copying another host's `.gitconfig.local` points git at a secret key that is not
  in the local keyring, and every signed commit fails. Generate or import a key, then put its id in the new
  `bash-<host>/.gitconfig.local`.
- **`usr/paraview.desktop` is stale.** It starts `/opt/paraview/5.12.0/bin/paraview`, while `bash/.bash/optprogs`
  puts ParaView 6.0.1 on `PATH`.
- **Do not put secrets in `claude_code.local`.** The `bash-<host>` packages are tracked in a public repository; keys
  and tokens belong in `bash/.bash/private`, see [bash](/packages/bash).
