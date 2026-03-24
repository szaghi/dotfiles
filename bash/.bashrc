#!/bin/bash
# Author: Stefano Zaghi <stefano.zaghi@gmail.com>
# Date: 09.09.2020
# ~/.bashrc

# if not running interactively, don't do anything
[ -z "$PS1" ] && return;

# load the bash dotfiles
for file in ~/.bash/{private,aliases,compilers,claude_code,exports,functions,optprogs,paths,prompt,welcome}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

# don't put duplicate lines in the history
export HISTCONTROL=$HISTCONTROL${HISTCONTROL+,}ignoredups

# append to the history file, don't overwrite it
shopt -s histappend

# check the window size after each command and, if necessary update the values of LINES and COLUMNS
shopt -s checkwinsize

# case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob;

# autocorrect typos in path names when using `cd`
shopt -s cdspell;

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)";

# enable some Bash 4 features when possible:
for option in autocd globstar; do
	shopt -s "$option" 2> /dev/null;
done;

# add tab completion for many Bash commands
if [ -f /etc/bash_completion ]; then
	source /etc/bash_completion;
fi;

# enable tab completion for `g` by marking it as an alias for `git`
if type _git &> /dev/null && [ -f /usr/local/etc/bash_completion.d/git-completion.bash ]; then
	complete -o default -o nospace -F _git g;
fi;

# add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2- | tr ' ' '\n')" scp sftp ssh;

# autocomplete to bd script
if [ -f "$HOME/.bash/completions/bd" ]; then
	source "$HOME/.bash/completions/bd";
fi;

# icons-in-terminal
if [ -f "$HOME/.local/share/icons-in-terminal/icons_bash.sh" ]; then
   source "$HOME/.local/share/icons-in-terminal/icons_bash.sh"
fi;

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# API keys are loaded from ~/.bash/private

[[ -f "$HOME/.bash_completions/mosaic.sh" ]] && source "$HOME/.bash_completions/mosaic.sh"
[[ -f "$HOME/.bash_completions/fobis.sh" ]] && source "$HOME/.bash_completions/fobis.sh"
