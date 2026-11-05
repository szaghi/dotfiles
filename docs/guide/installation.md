---
title: Fresh install
---

# Fresh install

From an empty account to a working environment: install the few tools the deployment needs, clone the
repository into `~/dotfiles`, create the directories that must stay real, deploy, then run the
per-machine steps that stow cannot do.

## 1. Install the prerequisites

The deployment itself needs only git, bash and GNU Stow. The rest is what the configuration expects
to find.

| Tool | Why | CachyOS / Arch | Ubuntu / WSL2 |
|---|---|---|---|
| git | clone and update | `pacman -S git` | `apt install git` |
| GNU Stow | links the packages | `pacman -S stow` | `apt install stow` |
| bash ≥ 4.4 | the shell (`autocd`, `globstar`) | preinstalled | preinstalled |
| vim | the editor | `pacman -S vim` | `apt install vim` |
| Lmod | HPC environment modules | `yay -S lmod` (AUR) | `apt install lmod` |
| fzf, rsync, bc | vim finders, shell functions | `pacman -S fzf rsync bc` | `apt install fzf rsync bc` |
| python3 | status line, helper scripts | `pacman -S python` | `apt install python3 python3-venv` |
| curl | local-LLM health checks | preinstalled | `apt install curl` |

Neovim, the LSP servers, the HPC toolchains, Claude Code and the desktop programs come later, in step 6.

## 2. Clone into `~/dotfiles`

```bash
git clone https://github.com/szaghi/dotfiles ~/dotfiles
```

The location is not free: `skills-apply`, `quark-desktop-install` and `astrobit-system-install` look
for the repository at `$HOME/dotfiles`.

## 3. Create the directories that must stay real

When a target directory does not exist yet, Stow links the **whole directory** into the repository
("tree folding") instead of linking the files inside it. Every file a program later writes there then
lands in the repository. For these directories that is wrong, so create them first:

```bash
mkdir -p ~/.ssh ~/.claude ~/.config ~/.local/share
chmod 700 ~/.ssh
```

| Directory | Why it must be real |
|---|---|
| `~/.ssh` | keys and `known_hosts` would be written into `ssh/.ssh/` |
| `~/.claude` | credentials, transcripts and memory would be written into `claude/.claude/` |
| `~/.config`, `~/.local/share` | every other program writes there |

Folding is intended for `~/.vim`, `~/.modules`, `~/.git-templates`, `~/.config/nvim` and
`~/.local/share/applications`: nothing but this repository writes into them (vim-plug's
`~/.vim/plugged` is gitignored).

## 4. Add the private file (optional)

Secrets and private settings (tokens, private hosts) go in `bash/.bash/private`, which is gitignored
and sourced by `.bashrc` when present. Copy yours from a backup:

```bash
cp /path/to/backup/private ~/dotfiles/bash/.bash/private
```

## 5. Deploy

Preview first, then link:

```bash
bash ~/dotfiles/dotify.sh --dry-run
bash ~/dotfiles/dotify.sh
```

This stows the common packages (`bash vim nvim git claude modules python scripts miscellanea ssh tmux`)
and then the packages listed in `machines/$(hostname -s)`. A conflict (a real file already where a link
must go) stops Stow without changing anything: move the file away and run it again.
[Stow and dotify.sh](/guide/dotify) explains every option.

Open a new shell, or `source ~/.bashrc`, to load the configuration.

## 6. Per-machine steps

Stow creates links; it does not install programs or touch root-owned files. These steps do:

| Step | Command | Where |
|---|---|---|
| Neovim (pinned, checksummed) and its CLI tools | `~/.scripts/install-nvim` | all |
| LSP servers shared by vim and Neovim | `~/.scripts/install-vim-lsp.sh` | adam (it needs `apt-get`) |
| vim plugins | start `vim`: vim-plug installs the missing ones on first launch | all |
| Claude Code skills (plugins and third-party) | `skills-apply install`, then restart Claude Code | all |
| Claude Code accounts | `claude-<account> login` once per account ([wrappers](/claude/wrappers)) | as needed |
| Crash check for git repositories | `systemctl --user daemon-reload && systemctl --user enable --now git-health-boot.service` | all |
| quark desktop: touchpad hwdb, WiFi power save | `~/.scripts/quark-desktop-install` | quark |
| quark desktop: Noctalia templates | enable `gtk3, gtk4, qt, foot, alacritty, btop, sway` in Noctalia's settings → Templates (GUI only) | quark |
| astrobit system files: WiFi power save, virtual EDID | `~/.scripts/astrobit-system-install` | astrobit |
| HPC toolchains | install NVIDIA HPC SDK, GCC, Open MPI under the paths the modulefiles expect | adam |

Details: [scripts](/packages/scripts), [HPC modules](/packages/modules),
[quark desktop](/packages/desktop-quark), [astrobit desktop](/packages/desktop-astrobit),
[Skills](/claude/skills).

## 7. Check

```bash
bash ~/dotfiles/dotify.sh --dry-run   # nothing left to link
module avail                          # the modulefiles are visible
skills-apply status                   # every declared skill installed
git-health -d 7                       # recently touched repositories are healthy
```

## Things to know

- **Machine packages follow the host name.** `dotify.sh` reads `machines/$(hostname -s)`. A new machine
  with no profile gets the common packages only; see [The machines](/guide/machines#adding-a-machine).
- **The git hooks are not installed by `git init`.** `.gitconfig` sets no `init.templateDir`; the
  template and hooks are explained in [git](/packages/git).
- **`install-vim-lsp.sh` is apt-only.** On CachyOS install the servers from pacman and npm by hand.
