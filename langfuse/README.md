# Claude Code → OTel Collector → Langfuse

Claude Code の OTel トレースを Collector で Langfuse の形式に変換して送る。コストの計算と、リポジトリごとの集計ができるようになる。

```
claude ──(鍵なし)──▶ localhost:4318 Collector ──(Basic 認証)──▶ langfuse-web:3000
```

- `claude` 関数（`.zsh/40-tools.zsh`）が送信先を Collector にし、起動したリポジトリ名を `git.repo` として付ける
- Collector が変換する内容
  - トークン数（`input_tokens` など）→ `langfuse.observation.usage_details`。Langfuse がこれに単価をかけてコストを出す
  - `git.repo` → タグ `repo:<リポジトリ名>`。リポジトリの外で起動したときは `repo:none`
  - ユーザーのプロンプト（`interaction` の `user_prompt`）→ Input 欄（observation とトレース）。metadata からは消す
  - アシスタントの応答は元のデータに無いので、Output 欄は空のまま
- Langfuse の鍵は Collector だけが持つ。claude の環境には渡らない

## セットアップ

1. Langfuse を docker compose で起動しておく（ネットワーク `langfuse_default` ができる）
2. `~/.langfuse.env` に鍵を書く（`chmod 600`）
   ```
   LANGFUSE_PUBLIC_KEY=pk-...
   LANGFUSE_SECRET_KEY=sk-...
   ```
3. Collector を起動する。`restart: unless-stopped` なので、次からは Docker と一緒に起動する
   ```
   docker compose -f ~/dotfiles/langfuse/compose.yml up -d
   ```

Collector に接続できないとき、`claude` 関数は送信せずに起動する（警告を出す）。

## 制約

- リポジトリ名は起動したときのもの。セッションの途中で別のリポジトリを触っても、起動したリポジトリに計上される
- キャッシュ書き込みの 5 分と 1 時間を区別できないので、すべて 5 分の単価で計算される（実際より少し安く出る）
- サブスクリプションで使っている場合、コストは API の料金で計算した目安で、実際の請求額ではない
