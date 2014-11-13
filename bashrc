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

if [ -e /lib/terminfo/x/xterm-256color ]; then
  export TERM='xterm-256color'
else
  export TERM='xterm-color'
fi
PS1="\n\[\e[30;1m\]|\[\e[m\]\[\e[38;5;220m\]\u\[\e[m\]\[\e[30;1m\]@\[\e[m\]\[\e[38;5;208m\]\h\[\e[m\]\[\e[30;1m\]|\[\e[m\]\[\e[38;5;220m\]\j\[\e[m\]\[\e[30;1m\]|\[\e[m\]\[\e[38;5;220m\]\@ \d\[\e[m\]\[\e[30;1m\]|\[\e[m\]\n\[\e[30;1m\]|\[\e[m\]\[\e[38;5;208m\]\w\[\e[m\]\[\e[30;1m\]|\[\e[m\]\[\e[38;5;110m\]\$(/bin/ls -1 | /usr/bin/wc -l | /bin/sed 's: ::g') files, \$(/bin/ls -lah | /bin/grep -m 1 total | /bin/sed 's/total //')b\[\e[m\]\[\e[30;1m\]|\[\e[m\]\n\[\e[30;1m\]|->\[\e[m\]"
PROMPT_COMMAND='echo -ne "\033]0;${HOSTNAME}\007"'

# welcome
if [ -f ~/.bash_welcome ]; then
  . ~/.bash_welcome
fi

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

# mails storing
MAIL=/var/spool/mail/stefano

xhost + >/dev/null

# variables exporting
export MAIL
export EDITOR="vim"
export PYLINTRC=~/.pylint.d/pylintrc
export PATH SHOST CPU HOSTNAME HOSTTYPE OSTYPE MACHTYPE SHELL INDEXSTYLE
