# ~/.bashrc

# if not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history
export HISTCONTROL=$HISTCONTROL${HISTCONTROL+,}ignoredups

# append to the history file, don't overwrite it
shopt -s histappend

# check the window size after each command and, if necessary update the values of LINES and COLUMNS
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# colors and prompt
if [ -e /lib/terminfo/x/xterm-256color ]; then
  export TERM='xterm-256color'
else
  export TERM='xterm-color'
fi
prompt_git() {
	local s='';
	local branchName='';

	# Check if the current directory is in a Git repository.
	if [ $(git rev-parse --is-inside-work-tree &>/dev/null; echo "${?}") == '0' ]; then

		# check if the current directory is in .git before running git checks
		if [ "$(git rev-parse --is-inside-git-dir 2> /dev/null)" == 'false' ]; then

			# Ensure the index is up to date.
			git update-index --really-refresh -q &>/dev/null;

			# Check for uncommitted changes in the index.
			if ! $(git diff --quiet --ignore-submodules --cached); then
				s+='+';
			fi;

			# Check for unstaged changes.
			if ! $(git diff-files --quiet --ignore-submodules --); then
				s+='!';
			fi;

			# Check for untracked files.
			if [ -n "$(git ls-files --others --exclude-standard)" ]; then
				s+='?';
			fi;

			# Check for stashed files.
			if $(git rev-parse --verify refs/stash &>/dev/null); then
				s+='$';
			fi;

		fi;

		# Get the short symbolic ref.
		# If HEAD isn’t a symbolic ref, get the short SHA for the latest commit
		# Otherwise, just give up.
		branchName="$(git symbolic-ref --quiet --short HEAD 2> /dev/null || \
			git rev-parse --short HEAD 2> /dev/null || \
			echo '(unknown)')";

		[ -n "${s}" ] && s=" [${s}]";

		echo -e "${1}${branchName}${blue}${s}";
	else
		return;
	fi;
}
tput sgr0;
bold=$(tput bold);
reset=$(tput sgr0);
black=$(tput setaf 0);
blue=$(tput setaf 33);
cyan=$(tput setaf 37);
green=$(tput setaf 64);
orange=$(tput setaf 166);
purple=$(tput setaf 125);
red=$(tput setaf 124);
violet=$(tput setaf 61);
white=$(tput setaf 15);
yellow=$(tput setaf 136);
smerald=$(tput setaf 6);
if [[ "${USER}" == "root" ]]; then
	userStyle="${red}";
else
	userStyle="${orange}";
fi;
if [[ "${SSH_TTY}" ]]; then
	hostStyle="${bold}${red}";
else
	hostStyle="${yellow}";
fi;
PS1="\[\033]0;\w\007\]";
PS1+="\[${bold}\]";
PS1+="\[${userStyle}\]\u";
PS1+="\[${smerald}\]@";
PS1+="\[${hostStyle}\]\h";
PS1+="\[${smerald}\](\@ \d)"
PS1+="\$(prompt_git \"${white} on ${violet}\")"; # Git repository details
PS1+="\n";
PS1+="\[${smerald}\]\w ";
PS1+="\[${smerald}\$(/bin/ls -1 | /usr/bin/wc -l | /bin/sed 's: ::g') files, \$(/bin/ls -lah | /bin/grep -m 1 total | /bin/sed 's/total //')b";
PS1+="\n";
PS1+="\[${yellow}\]→ \[${reset}\]";
export PS1;

# welcome
# if [ -f ~/.bash_welcome ]; then
#   . ~/.bash_welcome
# fi

# enable programmable completion features
if [ -f /etc/bash_completion ]; then
  . /etc/bash_completion
fi

# alias definitions
if [ -f ~/.bash_aliases ]; then
  . ~/.bash_aliases
fi

# paths inclusions
if [ -f ~/.bash_paths ]; then
  . ~/.bash_paths
fi

# opt programs inclusions
if [ -f ~/.bash_optprogs ]; then
  . ~/.bash_optprogs
fi

# compilers definitions
if [ -f ~/.bash_compilers ]; then
  . ~/.bash_compilers
fi

# xhost + >/dev/null

# variables exporting
export EDITOR="vim"
export PYLINTRC=~/.pylint.d/pylintrc
export LESS_TERMCAP_md="${yellow}";
export PATH SHOST CPU HOSTNAME HOSTTYPE OSTYPE MACHTYPE SHELL INDEXSTYLE
