# Claude Code のトレースを Langfuse に送る設定

## 現在の構成（WSL2 のみ）

- 2026-10-04 から OTel Collector 経由（bc047c3）。詳細は `langfuse/README.md`
- 構成図: `claude` ──(鍵なし)──▶ `localhost:4318` Collector ──(Basic 認証)──▶ `langfuse-web:3000`
- `claude` 関数（`.zsh/40-tools.zsh`）:
  - 送信先は `localhost:4318` で、鍵は読まない
  - 起動したリポジトリ名を `OTEL_RESOURCE_ATTRIBUTES=git.repo=<名前>` で付ける（worktree からでも元のリポジトリ名になる）
  - 環境変数はサブシェル内だけで設定する（シェルには残らない）
  - Collector に接続できないときは、送信せずにそのまま起動する
- Collector（`langfuse/compose.yml`、コンテナ `langfuse-otel-collector`）:
  - トークン数を `langfuse.observation.usage_details` に変換する（コストが計算される）
  - `git.repo` をタグ `repo:<名前>` に変換する（metrics API で Tags ごとに集計できることを確認済み）
  - ユーザーのプロンプトを Input 欄（observation とトレース）に移す。metadata からは消す（9eab19c）。応答は元のデータに無いので、Output 欄は空のまま
  - 鍵は `~/.langfuse.env` から Collector だけが読む
- 送信するもの: トレース（OTLP / `http/protobuf`）、ユーザーのプロンプト (`OTEL_LOG_USER_PROMPTS`)、アシスタントの応答 (`OTEL_LOG_ASSISTANT_RESPONSES`)
- 送らないもの: ツールの入出力 (`OTEL_LOG_TOOL_CONTENT`)、API の生データ (`OTEL_LOG_RAW_API_BODIES`)。秘密情報が入りうるため
- `langfuse-observability` プラグインは `settings.json` から外した（無効化）。ただし本体は `~/.claude/plugins/` に残っている

### `~/.langfuse.env`（git 管理外。`.gitignore` 済み）

```
LANGFUSE_PUBLIC_KEY=pk-...
LANGFUSE_SECRET_KEY=sk-...
```

権限は `chmod 600` にしておく。Collector の送信先は Docker 内部の `langfuse-web:3000` に固定しているので、`LANGFUSE_HOST` / `LANGFUSE_BASE_URL` は使わない。

## 用語

| 用語 | 意味 |
|---|---|
| OTel 方式 | Claude Code 内蔵の OpenTelemetry で、トレースを直接 Langfuse に送る方式。今回採用 |
| プラグイン方式 | `langfuse-observability` プラグインが hook で Claude Code の動作を拾って送る方式 |
| hook | Claude Code の動作の節目にスクリプトを差し込む仕組み |
| observation | Langfuse のトレース内の1件の記録（SPAN / GENERATION / TOOL など） |
| metadata | Langfuse の自由属性の置き場。OTel 方式はプロンプトやトークン数をここに入れる |

## OTel 方式とプラグイン方式の比較

調査日: 2026-10-03。「確認済み」はソースコードまたは Langfuse の API で確認した事実、「推測」は未確認。

### 取得できる情報

| 項目 | OTel 方式 | プラグイン方式 |
|---|---|---|
| 送信のタイミング | リアルタイム（Span 単位） | 応答が終わった後（`Stop` / `SessionEnd` の hook）に、まとめて送る |
| Langfuse の `input` / `output` | `null`（確認済み） | 入る（README、過去データ。確認済み） |
| プロンプト | metadata の `attributes.user_prompt` に入る（確認済み） | `input` に入る |
| アシスタントの応答 | 見つからなかった（確認済み）。`OTEL_LOG_ASSISTANT_RESPONSES=1` でも出ていない | 入る（`assistant_text`。過去データで確認済み） |
| thinking ブロック | 不明 | 入る（ソースで確認済み） |
| ツールの入出力 | 既定ではツール名と種別のみ。中身は `OTEL_LOG_TOOL_*` で追加（opt-in） | 入る（ソースで確認済み。20000 文字で切り詰め） |
| skill / subagent | 不明 | 入る（README で確認済み） |
| 画像 | 不明 | 入る（既定で有効。`CC_LANGFUSE_CAPTURE_IMAGES`） |
| トークン数 | metadata に入る。Langfuse の専用欄（`usageDetails`）は空（確認済み） | 専用欄に入り、コストも計算される（README の記載。実データでは未確認） |
| コスト | 計算されない（`totalCost` が `None`。確認済み） | 計算される（README の記載。実データでは未確認） |
| 所要時間 | 入る（`duration_ms`、`ttft_ms` など。確認済み） | 不明 |
| 権限確認の待ち時間 | 入る（`tool.blocked_on_user`。確認済み） | 不明 |
| ユーザー識別情報 | email、account_id、organization_id などが常に入る（確認済み） | 任意（`userConfig` で設定） |
| キャッシュトークン | 入る（`cache_read_tokens` など。確認済み） | 不明 |

OTel 方式は計測（時間・トークン・権限待ち）が細かく、プラグイン方式は会話の中身が細かい。

### セキュリティ

| 観点 | OTel 方式 | プラグイン方式 |
|---|---|---|
| 実行されるコード | Claude Code 本体のみ | サードパーティの Python スクリプト（約3,500行）を、`Stop` / `SessionEnd` のたびに自分の権限で実行する（確認済み） |
| 依存パッケージ | なし | 実行時に `uv` が PyPI から `langfuse>=4.7,<5` を取得する（確認済み）。固定されていないため、サプライチェーンの経路になりうる |
| 更新 | Claude Code の更新に従う | 手動更新。Anthropic 以外のマーケットプレイスは自動更新されない（README で確認済み） |
| 送る中身の既定 | 内容は opt-in（`OTEL_LOG_*` が既定オフ） | 既定で広く送る。トランスクリプト全体を読み、画像も既定で送る（ソースで確認済み） |
| 秘密情報のマスキング | なし | 見つからなかった（`mask` / `redact` を grep しても該当なし）。長さでの切り詰めのみ（既定 20000 文字） |
| 個人情報 | email、account_id、organization_id が常に入る（確認済み） | `userConfig` で設定した ID のみ（README より） |
| 認証情報の置き場所 | 直接送る場合は環境変数（`OTEL_EXPORTER_OTLP_HEADERS` に Basic 認証の文字列）。子プロセスにも継承される（推測）。2026-10-04 以降は Collector が鍵を持ち、claude の環境に鍵は渡さない | OS のキーチェーン（README の記載）。または環境変数 |
| 送信先の既定 | 無し。`claude` 関数が `LANGFUSE_HOST` で指定 | `LANGFUSE_BASE_URL` が無いと `https://cloud.langfuse.com`（EU クラウド）に送る（確認済み）。設定漏れで外部に送るリスク |
| 安定性 | トレースはベータ機能。属性名が変わる可能性 | プラグインのバージョンに依存 |

### どちらを選ぶか

- 計測（時間、トークン、権限待ち）が欲しい → OTel
- 会話の中身（`input` / `output`、応答、ツール結果、コスト）が欲しい → プラグイン
- 秘密情報をできるだけ外に出したくない → OTel（opt-in の仕組みがあるため）
- 併用は可能だが、同じ作業が2系統で記録され、集計（トークン・コスト）が二重になりうる

## 課題

### 1. input / output / トークン使用量が Langfuse の標準欄に入らない（解決済み: bc047c3 / 9eab19c）

- 解決: コストは解決（bc047c3）。Input 欄は解決（9eab19c）。Output（応答）は課題 7 へ
- 状況: トレースは届くが、`input` / `output` が `null`。`usageDetails` も空でコストも出ない
- 原因（調査済み）: Claude Code の OTel は、プロンプトやトークン数を独自の属性名（`user_prompt`、`input_tokens` など）で metadata に入れる。Langfuse が読む属性名とは違う
- 応答の文字列は、トレースに出ていない（未解決）
- 候補:
  1. このまま使う（metadata で見られる。API やエクスポートで自前集計できる）
  2. OTel Collector で属性名を Langfuse の形式に変換する（応答は元データに無いので入らない）
  3. プラグイン方式に戻す（`input` / `output` とコストが入る。セキュリティ上の違いは上の表を参照）
  4. 応答を送る設定を探す（`OTEL_LOG_TOOL_CONTENT`、`OTEL_LOG_RAW_API_BODIES` など。秘密情報に注意）
- 追加調査（2026-10-04）:
  - モデル名と単価は Langfuse が認識している（`claude-opus-5-5` に紐付き、単価も登録済み）。欠けているのはトークン数だけ
  - 候補 2 を検証した。OTel Collector（`otel/opentelemetry-collector-contrib`）の `transform` processor で、`llm_request` の span に `langfuse.observation.usage_details` を付けると、コストが計算された（テスト span で `totalCost` を確認済み）
    ```yaml
    - set(span.attributes["langfuse.observation.usage_details"], Format("{\"input\":%d,\"output\":%d,\"cache_read_input_tokens\":%d,\"cache_creation_input_tokens\":%d}", [span.attributes["input_tokens"], span.attributes["output_tokens"], span.attributes["cache_read_tokens"], span.attributes["cache_creation_tokens"]]))
    ```
  - 制約: OTel の属性ではキャッシュ書き込みの 5 分と 1 時間を区別できない。すべて 5 分の単価で計算されるので、実際より少し安く出る
  - 置き場所: `dotfiles/langfuse/` に置く（2026-10-04 決定）。理由は課題 6 を参照

### 2. 環境変数名の不一致（解決済み: bc047c3）

- 解決: 鍵は Collector が読み、送信先は固定にしたので、`LANGFUSE_HOST` も `LANGFUSE_BASE_URL` も不要になった
- `~/.langfuse.env` は `LANGFUSE_BASE_URL` を使っているが、`claude` 関数は `LANGFUSE_HOST` を必須にしている
- どちらかに揃える（未決定）。プラグインは `LANGFUSE_BASE_URL` を読む

### 3. `claude` 関数が鍵を claude の環境に渡している（解決済み: bc047c3）

- 解決: `claude` 関数は鍵を読まなくなった。`~/.zshrc.local` の `LANGFUSE_*` の export も削除した（バックアップは `~/.zshrc.local.bak`）。`~/dotfiles/.zshrc.local`（鍵入り、`.gitignore` の対象外）は `~/.zshrc.local.from-dotfiles.bak` に移した
- `set -a` で `~/.langfuse.env` を読み込むため、`LANGFUSE_SECRET_KEY` も claude の環境変数に入る（OTel に必要なのは `OTEL_*` だけ）
- claude が起動する子プロセス（Bash ツールなど）にも継承される可能性がある（推測）
- 対策の候補: `OTEL_*` だけを残して `LANGFUSE_*` を unset する。または `otelHeadersHelper`（ヘッダーを都度スクリプトで生成する）を使い、認証文字列を環境変数に置かない

### 4. 無効化したプラグインの扱い

- `settings.json` からは外したが、本体は `~/.claude/plugins/` に残っている（user スコープと、`dotfiles` の project スコープの2件）
- 完全に消すかどうか（未決定）。消す場合は `claude plugin uninstall langfuse-observability@langfuse-observability`

### 5. その他

- Mac でも使う場合の対応（現在は WSL2 のみ）
- `~/.langfuse.env` の権限が 644（`chmod 600` にする）
- トレースはベータ機能のため、属性名やスキーマが将来変わる可能性がある

### 6. 過去分のコストを Langfuse に取り込む（将来やる）

- やりたいこと: ccusage が読んでいる `~/.claude/projects/**/*.jsonl` からトークン数を取り出し、元の日時を付けて GENERATION として Langfuse に送る。コストは Langfuse が単価から計算する
- 確認済みの事実（2026-10-04、WSL2）:
  - 残っている期間は 2026-09-23 から（このマシンを使い始めた日）。API 呼び出しの件数（重複除外後）は 9 月 25,393 件、10 月 8,569 件
  - 1 件ごとに日時、モデル、トークン数、`sessionId`、`cwd`、`gitBranch` が入っている
  - キャッシュ書き込みは `cache_creation.ephemeral_5m_input_tokens` / `ephemeral_1h_input_tokens` に分かれている。そのため OTel 方式より正確なコストが出せる（Langfuse の単価は `input_cache_creation_5m` / `input_cache_creation_1h`）
- 方針:
  - ccusage と同じく `message.id` と `requestId` の組で重複を除く
  - 送るのはトークン数とメタデータだけにする。プロンプトや応答の本文は送らない
  - 送信先は OTLP の受け口（`/api/public/otel/v1/traces`）。テスト span で動作確認済み
- 注意:
  - 二重計上を防ぐ区切りが必要。2026-10-03 以降は OTel 方式（と検証時のプラグイン方式）のデータがある。常時送信を始めた `37098c9`（2026-10-03 16:34）より前だけを取り込む案
  - Mac の分は Mac の jsonl にあるので、Mac でも実行が必要
  - jsonl は既定で 30 日後に消える（`cleanupPeriodDays`）。取り込むまでに消えないよう、値を長くするか早めに実行する
  - 単価表が違うので、ccusage の金額と完全には一致しない。どちらも API の料金で計算した場合の目安
- 置き場所: `dotfiles/langfuse/` に置く（2026-10-04 決定）。Collector の設定（課題 1）と一緒にする
  - 理由: `claude` 関数と Langfuse 関係の設定が 1 か所にまとまる。Mac でも `git pull` で使える。Langfuse の clone（upstream）には手を入れない
  - 依存パッケージやテストが増えて大きくなったら、ディレクトリごと別リポジトリに移す

### 7. アシスタントの応答を Output 欄に出す（将来やる。優先度: 低）

- 現状: ユーザーの判断で、当面は Input だけでよい
- 理由: Claude Code の OTel トレースに応答の本文が入っていない。`OTEL_LOG_ASSISTANT_RESPONSES=1` を設定しても入らない
- 候補:
  - A. プラグイン方式を併用する（コストが二重に計上される。セキュリティ上の問題は比較の表を参照）
  - B. 自前の Stop hook で transcript から最後の応答を読み、Collector に送る（OTel のトレース ID がわからないので、同じトレースの Output 欄には入れられない。同じ session の別の記録になる）
  - C. `OTEL_LOG_RAW_API_BODIES` を使う（秘密情報を含む生データを丸ごと送る。トレースに入るかは未確認）
  - D. Claude Code の logs（イベント）を送り、Collector でトレースに作り変える（`OTEL_LOG_ASSISTANT_RESPONSES` は logs 用の設定かもしれない。未確認。Langfuse は logs を受け取れない）
- 次の一手: まず D を調べる（logs の中身を見るだけで済み、手間が小さい）

### 8. Collector の起動を Langfuse と連動させる（将来の検討。現時点では今のままでよい）

- 現状: Collector は `~/dotfiles/langfuse/compose.yml` で、Langfuse とは別に起動している。`restart: unless-stopped` なので Docker と一緒に起動するが、Langfuse を `docker compose down` で止めても Collector は残る
- 検討した案:
  - Langfuse の clone に直接置く: 一緒に起動・停止できる。ただし upstream の clone なので git で管理できず、Mac とも共有できない。`claude` 関数（dotfiles）と変換ルールが別の場所に分かれる
  - ファイルは dotfiles に置き、`~/work/private_github/langfuse/docker-compose.override.yml` をシンボリックリンクにする（有力な案）: Langfuse の `docker compose up` で Collector も起動する。リンクは `dotfilesLink.sh` で張る
- 判断（2026-10-04）: 今のままにする。必要になったらシンボリックリンクの案を検討する

## 参考

- Langfuse は v4 `events_only` モード。`/api/public/traces` は使えず、`/api/public/v2/observations` で読む
- プラグインのログ: `~/.claude/state/langfuse_hook.log`
