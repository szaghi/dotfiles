#!/usr/bin/env bash

mkdir -p ~/.bash
mkdir -p ~/.bin
mkdir -p ~/.config
mkdir -p ~/.desk/desks
mkdir -p ~/.git
mkdir -p ~/.scripts

dot=~/dotfiles

# links
# bash
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
ln -fs $dot/bash/prompt ~/.bash/prompt
ln -fs $dot/bash/welcome ~/.bash/welcome

# bin
ln -fs $dot/bin/act ~/.bin/act

# desks
ln -fs $dot/desks/nvidia-24.sh ~/.desk/desks/nvidia-24.sh
# ln -fs $dot/desks/mpich-3.3.2-intel-19.1.2.254.sh ~/.desk/desks/mpich-3.3.2-intel-19.1.2.254.sh
# ln -fs $dot/desks/openmpi-4.0.5-gnu-10.0.1.sh ~/.desk/desks/openmpi-4.0.5-gnu-10.0.1.sh
# ln -fs $dot/desks/openmpi-4.0.5-intel-19.1.2.254.sh ~/.desk/desks/openmpi-4.0.5-intel-19.1.2.254.sh
# ln -fs $dot/desks/openmpi-cuda-4.0.5-gnu-10.0.1.sh ~/.desk/desks/openmpi-cuda-4.0.5-gnu-10.0.1.sh
# ln -fs $dot/desks/openmpi-cuda-4.0.5-intel-19.1.2.254.sh ~/.desk/desks/openmpi-cuda-4.0.5-intel-19.1.2.254.sh

# git
ln -fs $dot/git/git_commit_message_template ~/.git/git_commit_message_template
ln -fs $dot/git/gitconfig ~/.gitconfig
ln -fs $dot/git/git-flow-completion/git-flow-completion.bash ~/.git/git-flow-completition

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
ln -fs $dot/scripts/images/jpg_rename ~/.scripts/jpg_rename
ln -fs $dot/scripts/images/nef_rename ~/.scripts/nef_rename
ln -fs $dot/scripts/images/overlap_image ~/.scripts/overlap_image
ln -fs $dot/scripts/images/scale_image ~/.scripts/scale_image
ln -fs $dot/scripts/images/trim_image ~/.scripts/trim_image
ln -fs $dot/scripts/iso/mountiso ~/.scripts/mountiso
ln -fs $dot/scripts/iso/umountiso ~/.scripts/umountiso
ln -fs $dot/scripts/miscellanea/jpg2mjpeg ~/.scripts/jpg2mjpeg
ln -fs $dot/scripts/miscellanea/mount_nas.sh ~/.scripts/mount_nas.sh
ln -fs $dot/scripts/miscellanea/mp4_rename ~/.scripts/mp4_rename
ln -fs $dot/scripts/miscellanea/png2xvid.sh ~/.scripts/png2xvid.sh
ln -fs $dot/scripts/miscellanea/pps ~/.scripts/pps
ln -fs $dot/scripts/miscellanea/proof_sheet.sh ~/.scripts/proof_sheet.sh

# vim
ln -fs $dot/vim/ ~/.vim
ln -fs $dot/vim/vimrc ~/.vimrc
