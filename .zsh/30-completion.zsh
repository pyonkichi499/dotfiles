# Completion (compinit, terraform, gcloud lazy load)

fpath=(~/.zsh/completion $fpath)

autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit -C
else
  compinit
fi

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

autoload -U +X bashcompinit && bashcompinit

if command -v terraform &>/dev/null; then
  complete -o nospace -C "$(command -v terraform)" terraform
fi

# gcloud completion: lazy-load on first gcloud/gsutil/bq invocation
if [[ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]]; then
  __gcloud_completions_loaded=0
  __load_gcloud_completions() {
    (( __gcloud_completions_loaded )) && return
    __gcloud_completions_loaded=1
    source "$HOME/google-cloud-sdk/completion.zsh.inc"
  }
  gcloud() { __load_gcloud_completions; command gcloud "$@" }
  gsutil() { __load_gcloud_completions; command gsutil "$@" }
  bq() { __load_gcloud_completions; command bq "$@" }
fi

# cdr (recent directories)
if [[ -n $(echo ${^fpath}/chpwd_recent_dirs(N)) && -n $(echo ${^fpath}/cdr(N)) ]]; then
  autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
  add-zsh-hook chpwd chpwd_recent_dirs
  zstyle ':completion:*' recent-dirs-insert both
  zstyle ':chpwd:*' recent-dirs-default true
  zstyle ':chpwd:*' recent-dirs-max 1000
  zstyle ':chpwd:*' recent-dirs-file "$HOME/.cache/chpwd-recent-dirs"
fi
