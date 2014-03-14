# ~/.bash_aliases

eval "`dircolors -b`"
alias ls='ls --color=auto'
alias ll='ls -lh'
alias la='ls -A'
alias l='ls -CF'
alias lsUUID='sudo blkid'
alias dir='ls --format=vertical'
alias vdir='ls --format=long'
alias cp='cp -i'
alias rm='rm -i'
alias mv='mv -i'
alias cd..='cd ..'
alias ..='cd ..'

# ssh
alias zwinprop1='ssh -X zaghi@winprop1.dma.uniroma1.it'
alias pcprop1='ssh -X zaghi@pcprop1.dma.uniroma1.it'
alias pcprop2='ssh -X zaghi@pcprop2.dma.uniroma1.it'
alias pcprop3='ssh -X zaghi@pcprop3.dma.uniroma1.it'
alias pcprop4='ssh -X zaghi@pcprop4.dma.uniroma1.it'
alias pcprop6='ssh -X zaghi@pcprop6.dma.uniroma1.it'
alias pcprop7='ssh -X zaghi@pcprop7.dma.uniroma1.it'
alias pcprop8='ssh -X zaghi@pcprop8.dma.uniroma1.it'
alias pcprop9='ssh -X zaghi@pcprop9.dma.uniroma1.it'
alias pcprop10='ssh -X zaghi@pcprop10.dma.uniroma1.it'
alias swinprop1='ssh -X sz1@winprop1.dma.uniroma1.it'
alias insean-riccardo='ssh -X riccardo@usvp.insean.it'
alias caspur-SP5_zaghi='ssh -X zaghi@man.caspur.it'
alias caspur-SP5_insean02='ssh -X insean02@man.caspur.it'
alias caspur-Matrix_insean01='ssh -X insean01@matrix.caspur.it'
alias caspur-Matrix_insean02='ssh -X insean02@matrix.caspur.it'
alias caspur-Matrix_zaghi='ssh -X zaghi@matrix.caspur.it'
alias riccardo-xps='ssh -X riccardo@10.1.6.195'
alias gummo='ssh -X stefano@gummo'
alias zeppo='ssh -X stefano@zeppo'
alias chico='ssh -X stefano@chico'
alias groucho='ssh -X stefano@groucho'
alias fermi='ssh -X szaghi00@login.fermi.cineca.it'
alias plx='ssh -X szaghi00@login.plx.cineca.it'
alias clusinsean='ssh -X stefano@cluster'
alias ingv='ssh -X stefano.zaghi@ingv'

# apt
alias apt-update='sudo apt-get update'
alias apt-upgrade='sudo apt-get upgrade'
alias apt-install='sudo apt-get install'
alias apt-remove='sudo apt-get remove'
alias apt-purge='sudo apt-get purge'
alias apt-search='sudo apt-cache search'

# yaourt
alias yaourt-update='yaourt -Syu ; yaourt -Su --aur'

# make
alias make='make -j 10'

# bashcalc
alias calc='sh ~/scripts/bashcalc.sh'

# vim
alias vim='vim --servername vimserver'

# gvim
alias gvim='gvim > /dev/null 2>&1'

# gvimdiff
alias gvimdiff='gvimdiff > /dev/null 2>&1'

# okular
alias okular='okular > /dev/null 2>&1'

# evince
alias evince='evince > /dev/null 2>&1'

# gimp
alias gimp='gimp > /dev/null 2>&1'

# eog
alias eog='eog > /dev/null 2>&1'

# pida
alias pida='pida > /dev/null 2>&1'

# latexmk
alias latexmk='latexmk -pdf'

# pdflatex
alias pdflatex='pdflatex -interaction=nonstopmode -halt-on-error'

# git
alias pushgithub-master='git push -u origin master'
alias pushgithub-AMR='git push -u origin AMR'
alias pushgithub-gh-pages='git push -u origin gh-pages'
alias pushgithub-master-local='git push -u zaghi-local master'

# gridgen
alias gridgen='/opt/arch/pointwise/PointwiseV16.02R4/pointwise'

# intel parallel studio
alias vtune='amplxe-gui > /dev/null 2>&1'
alias inspector='inspxe-gui > /dev/null 2>&1'
alias advisor='advixe-gui > /dev/null 2>&1'

# acroread
alias acroread='acroread > /dev/null 2>&1'
