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
export HISTSIZE=100000
export SAVEHIST=100000

export EDITOR=vim
# Set LANG only; LC_ALL would force-override every LC_* category
export LANG=en_US.UTF-8
export GPG_TTY=$(tty)
