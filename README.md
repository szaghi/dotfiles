<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/public/logo-dark.svg">
  <img src="docs/public/logo.svg" alt="dotfiles logo: ~/. drawn as a cyan tilde, a slash and an orange dot" width="112">
</picture>

# dotfiles
#### One home, three machines

[![Docs](https://github.com/szaghi/dotfiles/actions/workflows/docs.yml/badge.svg)](https://github.com/szaghi/dotfiles/actions/workflows/docs.yml)
[![Last commit](https://img.shields.io/github/last-commit/szaghi/dotfiles)](https://github.com/szaghi/dotfiles/commits/master)
[![License](https://img.shields.io/badge/license-WTFPL-blue.svg)](#copyrights)

> My environment as one git repository: bash, vim and Neovim, HPC toolchains, two Wayland desktops and a full
> Claude Code setup, deployed with GNU Stow by one command on a WSL2 workstation, a laptop and a telescope controller.

</div>

| 🔗 **One command**<br>`dotify.sh` over GNU Stow: every package mirrors `$HOME`; dry-run, uninstall, a guard for drifted settings | 🖥️ **Three machines**<br>adam (WSL2, HPC), quark (CachyOS, sway + Noctalia), astrobit (CachyOS, niri, telescopes) | 🐚 **bash**<br>A prompt with git state and loaded modules; aliases, functions, completions; secrets kept out of git | ✏️ **vim and Neovim**<br>Side by side, one key map, no shared state; LSP for Fortran, Python, LaTeX and bash |
|:---:|:---:|:---:|:---:|
| 🧮 **HPC toolchains**<br>Lmod modulefiles for NVIDIA HPC SDK, GCC and Open MPI, WSL2 GPU paths included | 🎨 **Wayland desktops**<br>sway and niri, foot, Noctalia theming, Sunshine remote desktop; Solarized everywhere | 🤖 **Claude Code**<br>Account wrappers, local LLM servers, skills synced per host, slash commands, hooks | 🌙 **Night protocol**<br>Unattended work as a chain of verified snapshots, committed by the owner in the morning |

>#### [Documentation](https://szaghi.github.io/dotfiles/)
> The [fresh install](https://szaghi.github.io/dotfiles/guide/installation), [how it works](https://szaghi.github.io/dotfiles/guide/dotify),
> every [package](https://szaghi.github.io/dotfiles/packages/bash), the [Claude Code setup](https://szaghi.github.io/dotfiles/claude/)
> and the [cookbook](https://szaghi.github.io/dotfiles/guide/cookbook) are on the
> [dotfiles website](https://szaghi.github.io/dotfiles/).

---

## Quick start

The repository must live at `~/dotfiles`. Create the directories that must stay real first: if they do not exist,
Stow links them into the repository and keys or credentials end up in git.

```bash
git clone https://github.com/szaghi/dotfiles ~/dotfiles
mkdir -p ~/.ssh ~/.claude ~/.config ~/.local/share && chmod 700 ~/.ssh
bash ~/dotfiles/dotify.sh --dry-run     # preview
bash ~/dotfiles/dotify.sh               # common packages + machines/$(hostname -s)
```

Update with `git -C ~/dotfiles pull && bash ~/dotfiles/dotify.sh`. The per-machine steps that Stow cannot do
(toolchains, LSP servers, skills, desktop installers) are in [Fresh install](https://szaghi.github.io/dotfiles/guide/installation).

> A dotfiles repository is not meant to be forked: it is a personal backup and, I hope, a source of inspiration.
> Take what is useful.

---

## Authors

- Stefano Zaghi — [@szaghi](https://github.com/szaghi)

## Copyrights

My dotfiles come from many years of GNU/Linux use and from countless people sharing their configs on the web.
Distributed under the terms of the [WTFPL — Do What the Fuck You Want to Public License](http://www.wtfpl.net/),
without any warranty.
