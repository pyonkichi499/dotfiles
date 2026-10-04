# claude-sandbox への移行プロンプト

別のリポジトリで、ホストの Claude Code に渡すプロンプト。そのリポジトリを `claude-sandbox` で開発できるように準備させる。
その Claude には `~/dotfiles` を読ませない。仕様は `claude-sandbox help`、準備の状況は `claude-sandbox doctor` で確認させる。下の「---」以降をそのまま貼る。

---

## やりたいこと

このリポジトリでの開発を、今後は Docker コンテナ内の Claude Code（`claude-sandbox` コマンド）で行う。
目的は `--dangerously-skip-permissions` で承認をすべて自動にすること。
あなた（ホストで動いている Claude）の仕事は、そのための準備をこのリポジトリ側で整えること。コンテナの起動は私が自分でやる。

以前、私が先走って指示したので、このリポジトリに Docker や環境変数の準備をすでに作っているかもしれない。まずそれを調べること。

## 前提（ホスト側はすべて準備済み。作り直さないこと）

- `claude-sandbox` コマンドの仕様は `claude-sandbox help` で確認する。`~/dotfiles` は読まないこと
- ホスト側の準備（トークン、既定のイメージ、ネットワーク、Langfuse への送信）ができているかは `claude-sandbox doctor` で確認する。このリポジトリでの `docker run` の中身は `claude-sandbox --dry-run` で確認できる
- `claude-sandbox` を引数なしや `run` で実行すると、承認なしのコンテナが起動する。あなたは `help`、`doctor`、`--dry-run` 以外を実行しないこと
- 認証（`CLAUDE_CODE_OAUTH_TOKEN`）、Langfuse への送信（`OTEL_*`）、git の名前とメールアドレス、共通の指示（日本語での返信、コミット規約、AI の署名を入れないこと）は `claude-sandbox` が自動でコンテナに渡す。リポジトリ側で用意しない
- コンテナ内でもコミットできる（署名なし）。push はホストで行う
- リポジトリ側に置けるのは `.claude-sandbox.toml`（`image` と `env`）だけ。追加のマウントはホスト側の設定にしか書けないので、必要なら案として私に出す

## 手順

各ステップの結果を報告し、変更する前には必ず私の承認を得ること。

### 1. 以前の準備の棚卸し（変更しない）

- `git status`、`git log`、未追跡のファイルから、Docker と Claude の準備に関係するものを探して一覧にする。例:
  - `Dockerfile`、`compose.yml`、`.devcontainer/`
  - `.env*`、`.envrc`
  - `.claude/settings*.json`
  - 起動スクリプト
- 次のものは、上の前提と重複または衝突するので、特に指摘する:
  - `CLAUDE_CODE_OAUTH_TOKEN`、`ANTHROPIC_API_KEY`、`OTEL_*`、`LANGFUSE_*` などの環境変数の定義
  - 独自の `docker run` やコンテナ起動の仕組み
- リポジトリの外（`~/.zshrc`、`~/.claude-sandbox.env` など）を変更した記憶や形跡があれば、それも報告する。ただし触らない
- それぞれに「残す / 削除する / 置き換える」の案を付けて、私の判断を待つ

### 2. コンテナで必要なものを洗い出す

- このリポジトリの言語、ビルド、テスト、リンターに必要なツールと、そのバージョンを調べる
- 既定のイメージで足りるか、用途別のイメージが必要かを判断する
- 用途別のイメージが必要なら、次の 2 点を案として出す:
  - Dockerfile の置き場所（このリポジトリにコミットするか、など）
  - イメージの指定方法（`.claude-sandbox.toml` の `image`、または毎回 `--image`）

### 3. ホストとコンテナで共有するものの落とし穴を確認する

マウントされるリポジトリはホストとコンテナの両方から使われる。次の点を確認する。

- 仮想環境やビルド成果物（`.venv`、`node_modules`、ビルドキャッシュなど）
  - ホストで作ったものがコンテナで動かないことがある。例: uv の `.venv` は、ホストの `~/.local/share/uv` にある Python を指しているが、そこはマウントされない
  - 逆に、コンテナで作ったものがホストで動かないこともある
  - 対策の案を出す。例: `.claude-sandbox.toml` の `env` で `UV_PROJECT_ENVIRONMENT` を設定し、コンテナ側は別のディレクトリを使う
- リポジトリ内の秘密情報（`.env` の API キーなど）
  - コンテナ内の Claude は承認なしで読める
  - 開発に本当に必要か、ダミーにできるかを確認する
- このリポジトリの `CLAUDE.md` / `AGENTS.md`、`.claude/settings.json`
  - コンテナ内でも読まれる。承認なしで動くことを前提に、コンテナ内の Claude への指示（テストの実行方法、コミットの単位など）が足りているか確認する
- git
  - `claude-sandbox doctor` の git の行を確認する。user.name / user.email が無い、`commit.gpgsign` がリポジトリの設定で有効、`core.hooksPath` がリポジトリ内を指している、のどれかがあれば、対策の案を出す

### 4. 実施

私が承認した案だけを実施する。イメージをビルドするなら、コマンドを示してから実行する。

### 5. 引き継ぎ

最後に次の 3 つを短くまとめる。

- 私が実行する起動コマンド（例: `claude-sandbox`、`claude-sandbox --image <名前>`）
- コンテナ内の Claude に最初に伝えるべきこと（テストの実行方法、push はホストで行うこと、など）
- 残っている課題
