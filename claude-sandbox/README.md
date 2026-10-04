# claude-sandbox

カレントのリポジトリを Docker コンテナにマウントし、Claude Code を `--dangerously-skip-permissions` で起動する。トレースはホストの `claude` 関数と同じく、Collector 経由で Langfuse に送る。

```
claude-sandbox ──▶ コンテナ (ネットワーク claude_sandbox) ──(鍵なし)──▶ Collector ──(Basic 認証)──▶ langfuse-web
                                                                         └ langfuse_default にも参加
```

仕様の詳細（オプション、設定ファイルの書き方、渡すもの / 渡さないもの）は `claude-sandbox help` に書いてある。別のリポジトリの Claude に仕様を伝えるときも、`~/dotfiles` を読ませずに `claude-sandbox help` を実行させればよい。そのリポジトリを移行するときに Claude へ渡すプロンプトは `setup-prompt.md`。

## 使い方

```bash
cd ~/work/some-repo
claude-sandbox                        # Claude Code を起動（run は省略できる）
claude-sandbox --image my-ml-image    # 用途別のイメージ
claude-sandbox -- -p "テストを直して"  # -- の後ろは claude の引数
claude-sandbox --dry-run              # 起動せずに docker run のコマンドを表示
claude-sandbox shell                  # 同じ設定のコンテナで bash（依存パッケージの確認など）
claude-sandbox doctor                 # 準備ができているかを確認
claude-sandbox build                  # 既定のイメージをビルド
claude-sandbox clean                  # このリポジトリ用のコンテナの HOME を削除
```

実装は uv script（Python、標準ライブラリのみ）。ホストに `uv` が必要。

## コンテナに渡すもの / 渡さないもの

| | 内容 |
|---|---|
| 渡す | リポジトリのルート（ホストと同じパスにマウント、読み書き可）。worktree なら共通の `.git` も |
| 渡す（読み取り専用） | `.git/config` と `.git/hooks` |
| 渡す | `~/.claude-sandbox.env` のトークン（`CLAUDE_CODE_OAUTH_TOKEN`） |
| 渡す | git の名前とメールアドレス（ホストの `git config` の値を `GIT_AUTHOR_*` / `GIT_COMMITTER_*` で） |
| 渡す（読み取り専用） | 共通の指示（`ai/AGENTS.md`）を `/etc/claude-code/CLAUDE.md` に、`managed-settings.json`（AI の署名を入れない設定）を `/etc/claude-code/managed-settings.json` に |
| 渡す（読み取り専用） | ホストの `~/.claude/skills` の skills を、コンテナの `~/.claude/skills/<名前>` に（リンク先の `~/.agents/skills/<名前>` をマウントする。claude.ai から同期される `synced` は除く） |
| 渡す | OTel の設定（`langfuse/claude-otel.env`、送信先、`git.repo`）。Collector に届くときだけ |
| 渡す | 設定ファイルの `env` と、ホスト側の設定の `mounts` |
| 渡す | ホスト側の設定の `devices`（`--device` と、デバイスの所有グループの `--group-add`）。ホストに無いか、キャラクタデバイスでなければ、警告を出して渡さずに起動する |
| 渡さない | ホストの `~/.claude`（認証情報と、全リポジトリの会話ログ） |
| 渡さない | `~/.ssh`、`~/.gitconfig`、GPG 鍵（コンテナからは push も署名もできない） |
| 渡さない | Langfuse の鍵（Collector だけが持つ） |
| 渡さない | gh とその認証（ホストのトークンはすべてのリポジトリへの書き込みと、SSH 鍵・GPG 鍵の追加ができる）。gh はホストで使う |
| 渡さない | ホストの `settings.json`、メモリー、statusline、plugins |

その他の制限:

- ホストの UID で動く（root ではない）。全 capability を外し、`no-new-privileges` を付ける。`devices` を渡しても変わらない（KVM は `/dev/kvm` への ioctl だけで使え、capability はいらない）
- コンテナの `HOME` は `~/.local/state/claude-sandbox/<名前>-<ハッシュ>/`。マウントするパスごとに分かれ、会話ログや設定はここに残る
- ネットワークは `claude_sandbox` のみ。同じネットワークにいるのは Collector だけで、Langfuse 本体のコンテナには直接届かない。ただし下の「既知の制約」を参照

### 共通の指示と設定を managed 設定で渡す理由

コンテナの `HOME` にはホストの `~/.claude` が無いので、そのままでは共通の指示（日本語で返信、コミット規約、AI の署名を入れない）が効かない。Claude Code の managed 設定（`/etc/claude-code/`）に読み取り専用で置くと、コンテナ内の Claude は書き換えも上書きもできない。`HOME` の `~/.claude` は今までどおり書き込み可能。

### `.git/config` と `.git/hooks` を読み取り専用にする理由

コンテナ内でもコミットできるよう `.git` は書き込み可能にしているが、`hooks` と `config`（`core.hooksPath`、`core.fsmonitor` など）を書き換えられると、ホストで `git commit` や `git status`（zsh のプロンプトも含む）を実行したときに、コンテナが仕込んだコードがホストの権限で動く。その経路を塞ぐため、この 2 つだけ読み取り専用で重ねる。

そのため、コンテナ内では `git config` の書き込み（`git remote add`、`git branch -u` など）はできない。コミット、ブランチの作成、`git stash` などはできる。

## 設定ファイル

| ファイル | 書けるもの | 置き場所の理由 |
|---|---|---|
| `<リポジトリ>/.claude-sandbox.toml` | `image`、`env` | リポジトリの開発環境の一部なので、リポジトリと一緒に管理する |
| `~/.config/claude-sandbox/config.toml` | リポジトリのパスごとに `image`、`env`、`mounts`、`devices` | 追加のマウントとデバイスはコンテナの外に広がる項目。リポジトリ内のファイルはコンテナ内の Claude が書き換えられる（`.git` 経由で別のブランチに仕込むこともできる）ので、ホスト側にだけ書けるようにした |

```toml
# <リポジトリ>/.claude-sandbox.toml
image = "my-ml-image"

[env]
UV_PROJECT_ENVIRONMENT = "/home/sandbox/.venv"   # ホストの .venv と分ける
```

```toml
# ~/.config/claude-sandbox/config.toml（git 管理外。マシンごと）
["~/work/some-repo"]
mounts = [
  { source = "~/datasets/foo", target = "/data" },                     # readonly の既定は true
  { source = "~/scratch", target = "/scratch", readonly = false },
]

["~/work/private_github/ai-kernel-bench"]
devices = ["/dev/kvm"]   # QEMU を KVM で動かす
```

- ホスト側の設定はリポジトリの設定より優先する。イメージの優先順は `--image` > `$CLAUDE_SANDBOX_IMAGE` > ホスト側の設定 > リポジトリの設定 > `claude-sandbox`
- `env` には `HOME`、`TERM`、`OTEL_*`、`GIT_AUTHOR_*` など、`claude-sandbox` が設定する変数は書けない
- `env` の値は `docker run` のコマンドラインに載る（`ps` で見える）。秘密情報は書かない

## セットアップ

1. トークンを発行して保存する（ホストで実行。ブラウザでの認証がある）
   ```bash
   claude setup-token
   # 表示されたトークンを書く
   printf 'CLAUDE_CODE_OAUTH_TOKEN=%s\n' '<トークン>' > ~/.claude-sandbox.env
   chmod 600 ~/.claude-sandbox.env
   ```
   権限が 600 でないと、`claude-sandbox` は起動しない
2. 既定のイメージをビルドする: `claude-sandbox build`
3. Collector を起動しておく（`../langfuse/README.md`）。ネットワーク `claude_sandbox` が無ければ先に作る
   ```bash
   docker network create claude_sandbox
   docker compose -f ~/dotfiles/langfuse/compose.yml up -d
   ```
   Collector に届かないとき、`claude-sandbox` は警告を出して、送信せずに起動する
4. `dotfilesLink.sh` で `~/.local/bin/claude-sandbox` にリンクされる
5. `claude-sandbox doctor` で確認する

## 用途別のイメージを作る

`Dockerfile` の「Claude Code」の部分を、用途のイメージの Dockerfile に足す。要件は次のとおり。

- `claude` が PATH にあり、どの UID からも実行できる
- `git`、`curl`、`ca-certificates` がある
- `ENTRYPOINT` が `claude ...` の引数をそのまま実行する（既定のままなら問題ない）

例（機械学習）:

```dockerfile
FROM python:3.12-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl git \
 && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir torch numpy pandas
# --- Claude Code（~/dotfiles/claude-sandbox/Dockerfile からコピー）---
RUN HOME=/opt/claude bash -c 'curl -fsSL https://claude.ai/install.sh | bash' \
 && ln -s "$(readlink -f /opt/claude/.local/bin/claude)" /usr/local/bin/claude \
 && chmod -R a+rX /opt/claude
ENV DISABLE_AUTOUPDATER=1
```

Claude Code の更新は、イメージの再ビルドで行う（コンテナ内では自動更新しない）。

## コンテナ内でのコミット

- 名前とメールアドレスは、ホストでそのリポジトリに対して `git config user.name` / `user.email` を実行した値。無ければコンテナ内ではコミットできない（起動時に警告が出る）
- 署名はされない。ホストで `commit.gpgsign=true` にしていても、コンテナには鍵も `~/.gitconfig` も無いので署名なしになる。リポジトリの `.git/config` で `commit.gpgsign` を有効にしていると、コンテナ内のコミットは失敗する（`doctor` が警告する）
- 署名が必要なら、push の前にホストで署名し直す（例: `git rebase --exec 'git commit --amend --no-edit -S' <起点>`）
- push はホストで行う

## 既知の制約

- **ホストで `0.0.0.0` に公開しているポートには届く**。コンテナからホスト（ゲートウェイ `172.x.0.1` や LAN の IP）経由で、`langfuse-web`（3000）、minio（9090）、他のプロジェクトの公開ポートに接続できる（2026-10-04 に実測）。`127.0.0.1` に限定して公開しているポートには届かない
- インターネットと LAN には出られる（Anthropic の API や、パッケージのインストールに必要なため）
- **リポジトリ内のファイルを経由して、ホストでコードが動く経路は残る**。`.git/config` と `.git/hooks` は塞いだが、次は塞げない。ホストで実行する前に差分を確認する
  - `Makefile`、`package.json` の scripts、テストなど、ホストで実行するファイル
  - リポジトリ内に作られた入れ子の `.git`（悪意のある `config` 付き）。ホストでそこに `cd` すると、zsh のプロンプトが git を実行する。同じ UID なので `safe.directory` は働かない
  - worktree の `.git/worktrees/<名前>/` の中身（`commondir` など）
  - `core.hooksPath` がリポジトリ内（husky の `.husky/` など）を指している場合のフック（`doctor` と起動時に警告する）
- トークン（`CLAUDE_CODE_OAUTH_TOKEN`）はコンテナの環境変数にあるので、コンテナ内の Claude からは読める。漏れた場合に失効させる手順は未確認
- リポジトリを `/tmp/claude-<UID>/` の下に置くと、コンテナ内でその親ディレクトリが root の所有で作られ、Claude Code が一時ディレクトリを使えずに止まる。`env` で `CLAUDE_CODE_TMPDIR = "/home/sandbox/tmp"` を設定すれば回避できる

## テスト

docker を使わない部分（引数の解析、設定ファイルの読み込みと検証、`docker run` の引数の組み立て）のテスト。

```bash
uv run --with pytest pytest ~/dotfiles/claude-sandbox/tests
```
