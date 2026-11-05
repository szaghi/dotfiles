---
layout: home

hero:
  name: dotfiles
  text: One home, three machines
  tagline: "Stefano Zaghi's environment as one git repository: bash, vim and Neovim, HPC toolchains, two Wayland desktops and a full Claude Code setup, deployed with GNU Stow by one command."
  image:
    light: /logo.svg
    dark: /logo-dark.svg
    alt: "the dotfiles logo: ~/."
  actions:
    - theme: brand
      text: Fresh install
      link: /guide/installation
    - theme: alt
      text: How it works
      link: /guide/dotify
    - theme: alt
      text: Cookbook
      link: /guide/cookbook
    - theme: alt
      text: View on GitHub
      link: https://github.com/szaghi/dotfiles

features:
  - title: One command to deploy
    details: "Every directory mirrors $HOME; dotify.sh links it with GNU Stow, adds each machine's own packages and stops before Claude Code's settings.json drift can be lost."
    link: /guide/dotify
    linkText: Stow and dotify.sh
  - title: Three machines, one repository
    details: "An HPC workstation on WSL2, a CachyOS laptop and a telescope controller, told apart by two small files in machines/."
    link: /guide/machines
    linkText: The machines
  - title: A shell that knows the toolchain
    details: "A prompt with git state and loaded Lmod modules, aliases and functions for HPC work, a 50k-line tmux."
    link: /packages/bash
    linkText: bash
  - title: vim and Neovim side by side
    details: "Two independent configurations with one key map, LSP for Fortran, Python, LaTeX and bash, Solarized in 24-bit."
    link: /packages/vim
    linkText: vim
  - title: HPC modules
    details: "Lmod modulefiles for NVIDIA HPC SDK, GCC, Open MPI, Intel and AMD, with the WSL2 workarounds built in."
    link: /packages/modules
    linkText: HPC modules
  - title: Two Wayland desktops
    details: "sway and Noctalia on quark, themed from one palette; niri and Sunshine on astrobit, streamed to any screen."
    link: /packages/desktop-quark
    linkText: quark desktop
  - title: Claude Code, configured
    details: "Global instructions, three classes of skills synced per host, slash commands, guard hooks, wrappers for every account and local LLM servers."
    link: /claude/
    linkText: Claude Code
  - title: Unattended work, reviewed in the morning
    details: "The night protocol snapshots every green step without touching git; one command from your terminal commits the night, signed."
    link: /claude/night-protocol
    linkText: Night protocol
---
