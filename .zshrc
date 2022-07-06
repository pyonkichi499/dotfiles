eval "$(starship init zsh)"

# set option+arrow to move / word
bindkey -e
bindkey '\e\e[C' forward-word
bindkey '\e\e[D' backward-word

setopt no_beep

fpath=(~/.zsh/completion $fpath)
autoload -U compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

export LSCOLORS=gxfxcxdxbxegedabagacad

alias ls="ls --color=auto"
alias ll="ls -GalFh"
alias zcat='gzcat'
alias grep="grep --color"

alias docker-compose="docker compose"

export HISTSIZE=10000
export SAVEHIST=1000000
setopt hist_ignore_dups
setopt share_history
setopt extended_history

# set docker host
export DOCKER_HOST=$(limactl list docker --format 'unix://{{.Dir}}/sock/docker.sock')

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
eval "$(pyenv init --path)"

eval "$(pyenv init -)"
setopt nonomatch

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/terauchi.hiroshi/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/terauchi.hiroshi/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/terauchi.hiroshi/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/terauchi.hiroshi/Downloads/google-cloud-sdk/completion.zsh.inc'; fi

autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/local/bin/terraform terraform
export PATH=/Users/terauchi.hiroshi/.nodebrew/current/bin:$PATH

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_COMPLETION_TRIGGER="," # default: '**'
source ~/.github/kwhrtsk/docker-fzf-completion/docker-fzf.zsh

# go path
export GOPATH=$HOME/go
export GOROOT="$(brew --prefix golang)/libexec"
export PATH="$PATH:${GOPATH}/bin:${GOROOT}/bin"

# goenv path
export GOENV_ROOT=$HOME/.goenv
export PATH=$GOENV_ROOT/bin:$PATH
export PATH=$HOME/.goenv/bin:$PATH
# eval "$(goenv init -)"

# jenv path
export PATH="$HONE/.jenv/bin:$PATH"
eval "$(jenv init -)"
export PATH="/usr/local/opt/ncurses/bin:$PATH"

# Add Visual Studio Code (code)
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

export JAVA_HOME=/Users/terauchi.hiroshi/Library/Java/JavaVirtualMachines/adopt-openjdk-11.0.11/Contents/Home

export EDITOR=zsh
eval "$(direnv hook zsh)"

# locale
export LC_ALL=en_US.UTF-8
export LANG=ja_JP.UTF-8

# activate venv
function cd() {
    builtin cd "$@"

    ## Default path to virtualenv in your projects
    DEFAULT_ENV_PATH="./venv"

    ## If env folder is found then activate the vitualenv
    function activate_venv() {
        if [[ -f "${DEFAULT_ENV_PATH}/bin/activate" ]]; then
            source "${DEFAULT_ENV_PATH}/bin/activate"
            echo "Activating ${VIRTUAL_ENV}"
        fi
    }

    if [[ -z "$VIRTUAL_ENV" ]]; then
        activate_venv
    else
        ## check the current folder belong to earlier VIRTUAL_ENV folder
        # if yes then do nothing
        # else deactivate then run a new env folder check
        parentdir="$(dirname ${VIRTUAL_ENV})"
        if [[ "$PWD"/ != "$parentdir"/* ]]; then
            echo "Deactivating ${VIRTUAL_ENV}"
            deactivate
            activate_venv
        fi
    fi
}
[ -f "/Users/terauchi.hiroshi/.ghcup/env" ] && source "/Users/terauchi.hiroshi/.ghcup/env" # ghcup-env
export PATH="/usr/local/sbin:$PATH"


if (which zprof > /dev/null 2>&1) ;then
  zprof
fi
export PATH="$HOME/.plenv/bin:$PATH"
eval "$(plenv init -)"

eval "$(anyenv init -)"

# Created by `pipx` on 2022-05-01 12:10:23
export PATH="$PATH:/Users/terauchi.hiroshi/.local/bin"
# START: Added by Updated Airflow Breeze autocomplete setup
# source /Users/terauchi.hiroshi/work/practice/sandbox/airflow_tmp/dev/breeze/autocomplete/breeze-complete-zsh.sh
# END: Added by Updated Airflow Breeze autocomplete setup
