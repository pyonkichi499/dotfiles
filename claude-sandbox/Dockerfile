# claude-sandbox の既定のイメージ（Claude Code と git だけの最小構成）
# ビルド: docker build -t claude-sandbox ~/dotfiles/claude-sandbox
#
# 用途別のイメージ（機械学習など）に Claude Code を入れるときは、下の「Claude Code」の部分をその Dockerfile に足す
# 要件:
#   - claude が PATH にあり、どの UID からも実行できる（claude-sandbox はホストの UID で起動する）
#   - git、curl、ca-certificates がある
FROM debian:bookworm-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl git less procps \
 && rm -rf /var/lib/apt/lists/*

# --- Claude Code ---
# 公式インストーラは $HOME 配下に入れるので、HOME を /opt/claude にして入れ、/usr/local/bin にリンクする
# 実行時は一般ユーザーなので自動更新できない。更新はイメージの再ビルドで行う
RUN HOME=/opt/claude bash -c 'curl -fsSL https://claude.ai/install.sh | bash' \
 && ln -s "$(readlink -f /opt/claude/.local/bin/claude)" /usr/local/bin/claude \
 && chmod -R a+rX /opt/claude
ENV DISABLE_AUTOUPDATER=1
# --- ここまで ---
