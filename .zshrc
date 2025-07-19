# set option+arrow to move / word
bindkey -e
bindkey '\e\e[C' forward-word
bindkey '\e\e[D' backward-word

setopt no_beep

fpath=(~/.zsh/completion $fpath)
autoload -U compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
 # rye run python の後にファイル補完 (_files) を有効にする
compdef _files rye run python
complete -o nospace -C /usr/local/bin/terraform terraform


export LSCOLORS=gxfxcxdxbxegedabagacad

alias ls="ls --color=auto"
alias ll="ls -GalFh"
alias grep="grep --color"
alias zcat='gzcat'

alias docker-compose="docker compose"
alias history='history -t "%F %T"'

export HISTSIZE=10000
export SAVEHIST=1000000
setopt hist_ignore_dups
setopt share_history
setopt extended_history


export PATH=/usr/local/bin:$PATH

# TODO: 将来 rye で管理するなら pyenv は消す
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/shims:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
export LDFLAGS="-L/opt/homebrew/opt/zlib/lib"
export CPPFLAGS="-I/opt/homebrew/opt/zlib/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/zlib/lib/pkgconfig"


setopt nonomatch

autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/local/bin/terraform terraform
export PATH=$HOME/.nodebrew/current/bin:$PATH

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
eval "$(goenv init -)"

# jenv path
export PATH="$HONE/.jenv/bin:$PATH"
eval "$(jenv init -)"
export PATH="/usr/local/opt/ncurses/bin:$PATH"

# Add Visual Studio Code (code)
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

export JAVA_HOME=$HOME/Library/Java/JavaVirtualMachines/adopt-openjdk-11.0.11/Contents/Home

export EDITOR=zsh
eval "$(direnv hook zsh)"

# locale
export LC_ALL=en_US.UTF-8
export LANG=ja_JP.UTF-8

export PATH="/usr/local/sbin:$PATH"
# alias haskell-stack
alias ghc='stack ghc --'
alias ghci='stack ghci --'
alias runghc='stack runghc --'
alias runhaskell='stack runhaskell --'

if (which zprof > /dev/null 2>&1) ;then
  zprof
fi
export PATH="$HOME/.plenv/bin:$PATH"
eval "$(plenv init -)"

eval "$(anyenv init -)"

# Created by `pipx` on 2022-05-01 12:10:23
export PATH="$PATH:$HOME/.local/bin"
# START: Added by Updated Airflow Breeze autocomplete setup
# source /Users/terauchi.hiroshi/work/practice/sandbox/airflow_tmp/dev/breeze/autocomplete/breeze-complete-zsh.sh
# END: Added by Updated Airflow Breeze autocomplete setup


### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/terauchi.hiroshi/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

# gcloud
# Use a python you have installed in a special location
export CLOUDSDK_PYTHON=$HOME/.pyenv/versions/3.9.17/bin/python

# cdr
if [[ -n $(echo ${^fpath}/chpwd_recent_dirs(N)) && -n $(echo ${^fpath}/cdr(N)) ]]; then
    autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
    add-zsh-hook chpwd chpwd_recent_dirs
    zstyle ':completion:*' recent-dirs-insert both
    zstyle ':chpwd:*' recent-dirs-default true
    zstyle ':chpwd:*' recent-dirs-max 1000
    zstyle ':chpwd:*' recent-dirs-file "$HOME/.cache/chpwd-recent-dirs"
fi

# The next line updates PATH for the Google Cloud SDK.
if [ -f '$HOME/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/terauchi.hiroshi/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '$HOME/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/terauchi.hiroshi/Downloads/google-cloud-sdk/completion.zsh.inc'; fi


# switch between m2 to rosetta
alias x86='arch -x86_64 zsh'
alias arm='arch -arm64e zsh'

if [ "$(uname -m)" = "arm64" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  export PATH="/opt/homebrew/bin:$PATH"
else
  eval "$(/usr/local/bin/brew shellenv)"
fi

# path for rye
 source "$HOME/.rye/env"

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"


[ -f "$HOME/.ghcup/env" ] && . "$HOME/.ghcup/env" # ghcup-envexport PATH="/usr/local/opt/openjdk/bin:$PATH"
export CPPFLAGS="-I/usr/localopt/openjdk/include"
export PATH="/usr/local/opt/openjdk/bin:$PATH"
export CPPFLAGS="-I/usr/local/opt/openjdk/include"

# starship
eval "$(starship init zsh)"
