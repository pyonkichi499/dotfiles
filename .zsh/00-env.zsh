# History, options, keybindings, locale

bindkey -e
bindkey '\e\e[C' forward-word
bindkey '\e\e[D' backward-word
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word
bindkey "^H" backward-kill-word
bindkey "^AK" kill-whole-line

setopt no_beep
setopt nonomatch
setopt hist_ignore_dups
setopt share_history
setopt extended_history

export HISTFILE=~/.zsh_history
export HISTSIZE=10000
export SAVEHIST=1000000

export EDITOR=vim
export LC_ALL=en_US.UTF-8
export LANG=ja_JP.UTF-8
export GPG_TTY=$(tty)
