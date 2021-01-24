export PS1="%T %/ %# "$'\n'"> "
eval "$(starship init zsh)"

setopt no_beep
autoload -U compinit
compinit

export LSCOLORS=gxfxcxdxbxegedabagacad
alias ls="ls -G"
alias ll="ls -GalFh"

export HISTSIZE=1000
export SAVEHIST=100000
setopt hist_ignore_dups

export PATH=/usr/local/bin:$PATH

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/terauchi.hiroshi/Desktop/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/terauchi.hiroshi/Desktop/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/terauchi.hiroshi/Desktop/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/terauchi.hiroshi/Desktop/google-cloud-sdk/completion.zsh.inc'; fi
source <(kubectl completion zsh)
alias zcat='gzcat'

eval "$(pyenv init -)"
setopt nonomatch
