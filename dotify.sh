#!/usr/bin/env bash

mkdir -p ~/.bash
mkdir -p ~/.bin
mkdir -p ~/.config
mkdir -p ~/.desk/desks
mkdir -p ~/.git
mkdir -p ~/.scripts
mkdir -p ~/.claude/commands

dot=~/dotfiles

# links
# bash
[ -f $dot/bash/private ] && ln -fs $dot/bash/private ~/.bash/private
ln -fs $dot/bash/aliases ~/.bash/aliases
ln -fs $dot/bash/bash_profile ~/.bash_profile
ln -fs $dot/bash/bashrc ~/.bashrc
ln -fs $dot/bash/compilers ~/.bash/compilers
ln -fs $dot/bash/dircolors.256dark ~/.dircolors.256dark
ln -fs $dot/bash/exports ~/.bash/exports
ln -fs $dot/bash/functions ~/.bash/functions
ln -fs $dot/bash/inputrc ~/.inputrc
ln -fs $dot/bash/optprogs ~/.bash/optprogs
ln -fs $dot/bash/paths ~/.bash/paths
ln -fs $dot/bash/claude_code ~/.bash/claude_code
ln -fs $dot/bash/prompt ~/.bash/prompt
ln -fs $dot/bash/welcome ~/.bash/welcome

# bin
ln -fs $dot/bin/act ~/.bin/act

# desks
for desk in $dot/desks/*.sh; do
  ln -fs "$desk" ~/.desk/desks/"$(basename "$desk")"
done

# git
ln -fs $dot/git/git_commit_message_template ~/.git/git_commit_message_template
ln -fs $dot/git/gitconfig ~/.gitconfig
# latex
ln -fs $dot/miscellanea/latexmkrc ~/.latexmkrc

# python
ln -fs $dot/python/pythonrc ~/.pythonrc
ln -fs $dot/python/pylintrc ~/.pylintrc

# scripts
ln -fs $dot/scripts/borg-automated-backup/borg-automated-backup.sh ~/.scripts/borg-automated-backup.sh
ln -fs $dot/scripts/desk/desk ~/.scripts/desk
ln -fs $dot/scripts/images/alpha_image ~/.scripts/alpha_image
ln -fs $dot/scripts/images/convert_image ~/.scripts/convert_image
ln -fs $dot/scripts/images/crop_image ~/.scripts/crop_image
ln -fs $dot/scripts/images/gray_image ~/.scripts/gray_image
ln -fs $dot/scripts/images/image2pdf ~/.scripts/image2pdf
ln -fs $dot/scripts/images/jpg_rename ~/.scripts/jpg_rename
ln -fs $dot/scripts/images/nef2jpg_thumb ~/.scripts/nef2jpg_thumb
ln -fs $dot/scripts/images/nef_rename ~/.scripts/nef_rename
ln -fs $dot/scripts/images/overlap_image ~/.scripts/overlap_image
ln -fs $dot/scripts/images/scale_image ~/.scripts/scale_image
ln -fs $dot/scripts/images/trim_image ~/.scripts/trim_image
ln -fs $dot/scripts/iso/mountiso ~/.scripts/mountiso
ln -fs $dot/scripts/iso/umountiso ~/.scripts/umountiso
ln -fs $dot/scripts/miscellanea/archive.sh ~/.scripts/archive.sh
ln -fs "$dot/scripts/miscellanea/Ds+.sh" ~/.scripts/Ds+.sh
ln -fs $dot/scripts/miscellanea/jpg2mjpeg ~/.scripts/jpg2mjpeg
ln -fs $dot/scripts/miscellanea/md-preview.sh ~/.scripts/md-preview.sh
ln -fs $dot/scripts/miscellanea/mount_nas.sh ~/.scripts/mount_nas.sh
ln -fs $dot/scripts/miscellanea/mp4_rename ~/.scripts/mp4_rename
ln -fs $dot/scripts/miscellanea/png2xvid.sh ~/.scripts/png2xvid.sh
ln -fs $dot/scripts/miscellanea/pps ~/.scripts/pps
ln -fs $dot/scripts/miscellanea/proof_sheet.sh ~/.scripts/proof_sheet.sh
ln -fs $dot/scripts/miscellanea/rainix ~/.scripts/rainix
ln -fs $dot/scripts/miscellanea/rwd ~/.scripts/rwd
ln -fs $dot/scripts/miscellanea/texcount.pl ~/.scripts/texcount.pl

# vim
ln -fs $dot/vim/ ~/.vim
ln -fs $dot/vim/vimrc ~/.vimrc

# claude
ln -fs $dot/claude/CLAUDE.md ~/.claude/CLAUDE.md
ln -fs $dot/claude/settings.json ~/.claude/settings.json
ln -fs $dot/claude/settings.local.json ~/.claude/settings.local.json
ln -fs $dot/claude/statusline-command.sh ~/.claude/statusline-command.sh
ln -fs $dot/claude/commands/semantic-commit.md ~/.claude/commands/semantic-commit.md
