# Tools: uv, gcloud, fzf, ghcup, bun, fnm

# uv (lazy-load completion on first invocation)
if command -v uv &>/dev/null; then
  __uv_completion_loaded=0
  __load_uv_completion() {
    (( __uv_completion_loaded )) && return
    __uv_completion_loaded=1
    eval "$(uv generate-shell-completion zsh 2>/dev/null)" || true
  }
  uv() {
    __load_uv_completion
    command uv "$@"
  }
fi

# gcloud (PATH only; completion is lazy-loaded in 30-completion.zsh)
if [[ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]]; then
  source "$HOME/google-cloud-sdk/path.zsh.inc"
fi
if [[ -x "$HOME/.gcloud-venv/bin/python" ]]; then
  export CLOUDSDK_PYTHON="$HOME/.gcloud-venv/bin/python"
fi

# fzf
if command -v fzf &>/dev/null; then
  source <(fzf --zsh)
  export FZF_COMPLETION_TRIGGER=","
fi

# docker-fzf (optional)
[[ -f "$HOME/.github/kwhrtsk/docker-fzf-completion/docker-fzf.zsh" ]] &&
  source "$HOME/.github/kwhrtsk/docker-fzf-completion/docker-fzf.zsh"

# ghcup
[[ -f "$HOME/.ghcup/env" ]] && source "$HOME/.ghcup/env"

# bun
export BUN_INSTALL="$HOME/.bun"
[[ -d "$BUN_INSTALL/bin" ]] && export PATH="$BUN_INSTALL/bin:$PATH"
[[ -s "$BUN_INSTALL/_bun" ]] && source "$BUN_INSTALL/_bun"

# fnm
export FNM_DIR="$HOME/.local/share/fnm"
[[ -d "$FNM_DIR" ]] && export PATH="$FNM_DIR:$PATH"
if command -v fnm >/dev/null 2>&1; then
  mkdir -p "$HOME/.local/state"
  if [[ -z "${XDG_RUNTIME_DIR:-}" || ! -w "$XDG_RUNTIME_DIR" ]]; then
    export XDG_RUNTIME_DIR="$HOME/.local/state"
  fi
  mkdir -p "$XDG_RUNTIME_DIR/fnm_multishells" 2>/dev/null || true

  __fnm_env="$(fnm env --shell zsh 2>/dev/null)"
  if [[ -n "$__fnm_env" ]]; then
    eval "$__fnm_env"
  elif [[ -d "$FNM_DIR/aliases/default/bin" ]]; then
    export PATH="$FNM_DIR/aliases/default/bin:$PATH"
  fi
  unset __fnm_env
fi

# claude: Claude Code のトレースを OTel Collector (langfuse/compose.yml) 経由で Langfuse に常時送信する
# 認証情報は Collector だけが持つので、claude の環境には鍵を渡さない
# Collector が起動していないときは、送信せずにそのまま起動する
claude() {
  local endpoint="http://localhost:4318"
  if ! curl -s -o /dev/null -m 1 "$endpoint"; then
    echo "claude: OTel Collector ($endpoint) に接続できないため、Langfuse へ送信せずに起動します" >&2
    command claude "$@"
    return
  fi
  (
    # リポジトリごとに集計できるよう、起動したリポジトリ名を付ける（worktree からでも元のリポジトリ名になる）
    local git_dir repo=none
    if git_dir=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null); then
      [[ $git_dir == */.git ]] && repo=${git_dir:h:t} || repo=${${git_dir:t}%.git}
    fi
    # claude-sandbox と共通の設定
    set -a
    source "$HOME/dotfiles/langfuse/claude-otel.env"
    set +a
    export OTEL_EXPORTER_OTLP_TRACES_ENDPOINT="$endpoint/v1/traces"
    export OTEL_RESOURCE_ATTRIBUTES="git.repo=${repo//[^A-Za-z0-9._-]/_}"
    command claude "$@"
  )
}
