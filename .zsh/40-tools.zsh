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

# claude: Claude Code のトレースを Langfuse (OTLP) に常時送信する
# 認証情報は git 管理外の ~/.langfuse.env (LANGFUSE_HOST / LANGFUSE_PUBLIC_KEY / LANGFUSE_SECRET_KEY) に置く
# ファイルが無い、または項目が足りないときは、送信せずにそのまま起動する
claude() {
  local env_file="$HOME/.langfuse.env"
  [[ -f "$env_file" ]] || { command claude "$@"; return; }
  (
    set -a; source "$env_file"; set +a
    if [[ -z "${LANGFUSE_HOST:-}" || -z "${LANGFUSE_PUBLIC_KEY:-}" || -z "${LANGFUSE_SECRET_KEY:-}" ]]; then
      echo "claude: $env_file に LANGFUSE_HOST / LANGFUSE_PUBLIC_KEY / LANGFUSE_SECRET_KEY が揃っていないため、Langfuse へ送信せずに起動します" >&2
    else
      local auth
      auth=$(printf '%s:%s' "$LANGFUSE_PUBLIC_KEY" "$LANGFUSE_SECRET_KEY" | base64 | tr -d '\n')
      export CLAUDE_CODE_ENABLE_TELEMETRY=1
      export CLAUDE_CODE_ENHANCED_TELEMETRY_BETA=1
      export OTEL_TRACES_EXPORTER="otlp"
      export OTEL_LOG_USER_PROMPTS=1
      export OTEL_LOG_ASSISTANT_RESPONSES=1
      export OTEL_EXPORTER_OTLP_PROTOCOL="http/protobuf"
      export OTEL_EXPORTER_OTLP_TRACES_ENDPOINT="${LANGFUSE_HOST%/}/api/public/otel/v1/traces"
      export OTEL_EXPORTER_OTLP_HEADERS="Authorization=Basic ${auth}"
    fi
    command claude "$@"
  )
}
