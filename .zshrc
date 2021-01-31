export PS1="%T %/ %# "$'\n'"> "
eval "$(starship init zsh)"

setopt no_beep
autoload -U compinit
compinit

export LSCOLORS=gxfxcxdxbxegedabagacad
alias ls="ls -G"
alias ll="ls -GalFh"
alias zcat='gzcat'

export HISTSIZE=1000
export SAVEHIST=100000
setopt hist_ignore_dups

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
