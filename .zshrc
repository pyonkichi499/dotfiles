export PS1="%T %/ %# "$'\n'"> "
eval "$(starship init zsh)"

setopt no_beep

fpath=(~/.zsh/completion $fpath)
autoload -U compinit
compinit

export LSCOLORS=gxfxcxdxbxegedabagacad
alias ls="ls -G"
alias ll="ls -GalFh"
alias zcat='gzcat'
alias grep="grep --color"

export HISTSIZE=10000
export SAVEHIST=1000000
setopt hist_ignore_dups
setopt share_history
setopt extended_history

export PATH=/usr/local/bin:$PATH

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/terauchi.hiroshi/anaconda3/bin/conda' 'shell.zsh' 'hook' 2>/dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/terauchi.hiroshi/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/terauchi.hiroshi/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/terauchi.hiroshi/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
setopt nonomatch

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/terauchi.hiroshi/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/terauchi.hiroshi/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/terauchi.hiroshi/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/terauchi.hiroshi/Downloads/google-cloud-sdk/completion.zsh.inc'; fi

autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/local/bin/terraform terraform
export PATH=/Users/terauchi.hiroshi/.nodebrew/current/bin:$PATH

if [ -e ~/.zsh/completions ]; then
    fpath=(~/.zsh/completions $fpath)
fi

autoload -Uz compinit
compinit

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_COMPLETION_TRIGGER="," # default: '**'
source ~/.github/kwhrtsk/docker-fzf-completion/docker-fzf.zsh

# go path
export GOPATH=$HOME/go
export GOROOT="$(brew --prefix golang)/libexec"
export PATH="$PATH:${GOPATH}/bin:${GOROOT}/bin"

# jenv path
export PATH="$HONE/.jenv/bin:$PATH"
eval "$(jenv init -)"
export PATH="/usr/local/opt/ncurses/bin:$PATH"
