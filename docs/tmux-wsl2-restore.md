# tmux WSL2 移行メモ — 状況整理と自動復元までの道筋

最終更新: 2026-07-04

## 試行手順書（これからやること）

**ゴール:** `tmux` を起動したら、前回のウィンドウ構成が自動で復元される。

**現状:** 安定性優先で `@continuum-restore 'off'`。手動 save/restore の確認から始める。

**キー操作の前提:** prefix = `Ctrl-q`

| 操作 | キー |
|------|------|
| 保存 | `Ctrl-q` → `Ctrl-s` |
| 復元 | `Ctrl-q` → `Ctrl-r` |
| デタッチ（終了ではない） | `Ctrl-q` → `d` |

---

### Step 0: 起動確認（5 分）

```bash
tmux kill-server 2>/dev/null
tmux
```

- [ ] tmux が開き、`[exited]` にならない
- [ ] 新規ウィンドウ（`Ctrl-q` → `c`）が作れる

**NG の場合:** `@continuum-restore` が `off` か確認。`wc -c ~/.local/share/tmux/resurrect/last` が 0 なら `last` を修正。

---

### Step 1: WSL2 用セッションを作る（10〜15 分）

macOS 時代の保存は使わず、今後使う構成を tmux 上で作り直す。

1. tmux 起動
2. 日常使うウィンドウを 2〜3 個作る（`Ctrl-q` → `c`）
3. 各 pane で `cd` し、**WSL 上に実在するパス**に移動
4. ウィンドウ名を付ける（任意）: `Ctrl-q` → `,`

- [ ] 各 pane で zsh が `[exited]` にならない
- [ ] cwd が `/home/hiroshi/...` など WSL 内のパス

**任意 — 古い保存を退避:**

```bash
mkdir -p ~/.local/share/tmux/resurrect/archive
mv ~/.local/share/tmux/resurrect/tmux_resurrect_*.txt \
   ~/.local/share/tmux/resurrect/archive/ 2>/dev/null
rm -f ~/.local/share/tmux/resurrect/last
```

---

### Step 2: 手動 save の確認（5 分）

1. Step 1 のセッション構成のまま
2. **`Ctrl-q` → `Ctrl-s`**（保存）
3. 別ターミナルで確認:

```bash
wc -c ~/.local/share/tmux/resurrect/last    # 0 より大きいこと
head -3 ~/.local/share/tmux/resurrect/last  # pane/window 行があること
```

- [ ] `last` が空でない（目安: 数百 bytes 以上）
- [ ] 中身に Step 1 で作ったウィンドウ数が反映されている

**NG の場合:** TPM プラグインが読み込まれているか確認（`tmux list-keys | grep save`）。

---

### Step 3: 手動 restore の確認（10 分）

1. **`Ctrl-q` → `Ctrl-s`** で再保存（念のため）
2. **`Ctrl-q` → `d`** でデタッチ
3. tmux サーバーを完全停止:

```bash
tmux kill-server
```

4. 再起動:

```bash
tmux
```

5. **`Ctrl-q` → `Ctrl-r`**（手動復元）
6. ウィンドウ数・cwd が Step 1 の状態に戻るか確認

- [ ] ウィンドウ構成が復元される
- [ ] 各 pane が `[exited]` にならない

**NG の場合:**

| 症状 | 対処 |
|------|------|
| 一部 pane が dead | その pane の cwd が存在しない → Step 1 やり直し |
| 全部 dead | Step 4（`.zshrc` 修正）へ |
| 何も起きない | `wc -c last` を再確認 |

---

### Step 4: `.zshrc` の WSL2 対応（必要なら 15 分）

Step 3 で pane が `[exited]` になる場合のみ。

切り分け:

```bash
# .tmux.conf の default-shell を一時的に bash に変更して restore テスト
# → bash なら OK / zsh なら NG → .zshrc が原因
```

修正対象の例（`~/.zshrc`）:

- `GOROOT="$(brew --prefix golang)/libexec"` → `command -v brew` でガード
- `/opt/homebrew`, Rancher Desktop (macOS パス) 等

修正後、Step 1 からやり直す。

- [ ] restore 後も zsh が生きている

---

### Step 5: 自動 restore を有効化（10 分）

Step 2・3 が **2 回連続成功** してから。

1. `~/dotfiles/.tmux.conf` を編集:

```tmux
set -g @continuum-restore 'on'
```

2. 起動前に `last` が正常か確認:

```bash
wc -c ~/.local/share/tmux/resurrect/last
```

3. 安定性テスト（10 回）:

```bash
for i in $(seq 1 10); do
  tmux kill-server 2>/dev/null; sleep 0.3
  tmux new-session -d && sleep 2 && tmux list-sessions >/dev/null \
    && echo "run $i: OK" || echo "run $i: FAIL"
done
```

4. 対話起動:

```bash
tmux kill-server && tmux
```

- [ ] 10 回テスト全部 OK
- [ ] 対話起動で Step 1 の構成が **自動的に** 復元される
- [ ] 起動後 2 秒以内に落ちない

**NG の場合:** すぐ `off` に戻す。`touch ~/tmux_no_auto_restore` で restore 一時停止。

---

### Step 6: 日常運用の確立

**終了するとき（毎回）:**

```
1. Ctrl-q → Ctrl-s   # 明示的に保存
2. Ctrl-q → d        # デタッチ
```

**次回:**

```bash
tmux    # restore on なら自動復元
```

**完全停止するとき:**

```bash
Ctrl-q → Ctrl-s      # 先に保存
tmux kill-server
```

---

### Step 7（任意）: 定期自動保存の調整

15 分ごとの自動保存で足りなければ `.tmux.conf` に追加:

```tmux
set -g @continuum-save-interval '5'   # 5 分ごと
```

---

### Step 8（任意）: Ghostty から tmux 自動起動

Step 5 安定後。`~/.config/ghostty/config` で tmux を直接起動する設定を検討。

---

### 進捗チェックリスト（一覧）

```
[ ] Step 0  起動確認
[ ] Step 1  WSL2 セッション作成
[ ] Step 2  手動 save 確認
[ ] Step 3  手動 restore 確認
[ ] Step 4  .zshrc 修正（必要なら）
[ ] Step 5  @continuum-restore 'on' + 10 回テスト
[ ] Step 6  日常運用（save → detach）
[ ] Step 7  自動保存間隔調整（任意）
[ ] Step 8  Ghostty 連携（任意）
```

---

## 環境

| 項目 | 値 |
|------|-----|
| OS | WSL2 (Ubuntu), kernel 6.18.x |
| ターミナル | Ghostty (`~/.config/ghostty/config`) |
| tmux | 3.6 |
| 設定ファイル | `~/.tmux.conf` → `~/dotfiles/.tmux.conf` (symlink) |
| シェル | zsh (`set -g default-shell /bin/zsh`) |
| プラグイン管理 | TPM (`~/.tmux/plugins/tpm`) |

### インストール済みプラグイン

- `tmux-plugins/tpm`
- `tmux-plugins/tmux-resurrect` — セッション手動/自動保存・復元
- `tmux-plugins/tmux-continuum` — 定期保存 + 起動時自動復元 + (任意) ログイン時 boot

---

## 発生していた問題

### 症状

1. `tmux` 実行直後に `[exited]` 表示、または即終了
2. `tmux -vv`（デバッグモード）では起動することがある
3. `~/.tmux.conf` を退避すると正常起動 → **原因は `.tmux.conf` 内の設定**
4. 設定を部分的にコメントアウト後も、**たまに起動・たまに落ちる** 不安定さが残った

### 切り分けで判明したこと

| テスト条件 | 結果 |
|-----------|------|
| `.tmux.conf` なし | 正常 |
| `@continuum-restore 'off'` | **5/5 安定** |
| `@continuum-restore 'on'` | **0/5** — 起動後 ~2 秒以内にセッション消失 |

---

## 根本原因（確定）

### 1. TPM の二重起動（初期クラッシュの原因）

以前の `.tmux.conf` には TPM 起動行が **2 行** あった:

```tmux
run '~/.tmux/plugins/tpm/tpm'      # 同期実行
run -b '~/.tmux/plugins/tpm/tpm'    # 非同期実行（末尾）
```

プラグインが二重読み込みされ、continuum の restore 等が競合しやすい。
`tmux -vv` だけ動くのは、デバッグモードでタイミングが変わりレースが表面化しにくいため。

**対処:** `run` は **末尾に 1 行だけ**（`-b` なし推奨）。

### 2. `@continuum-restore 'on'` + 壊れた resurrect ファイル（不安定化の原因）

起動フロー:

```
tmux 起動
  → デフォルトセッション作成
  → continuum が ~1 秒後に restore スクリプトをバックグラウンド実行
  → resurrect/last の内容でセッションを上書き復元
  → 失敗 or 空データ → セッション消失 / [exited]
```

問題のファイル:

```
~/.local/share/tmux/resurrect/last
  → tmux_resurrect_20260702T001831.txt  (0 バイト = 空)  ← 壊れていた

~/.local/share/tmux/resurrect/tmux_resurrect_20260701T193741.txt  (1018 バイト)  ← 正常
```

空ファイルへの restore が走るとセッションが消える。`last` の向き先が状況によって変わるため「たまに動く」ように見えた。

### 3. macOS 向け設定の残存（WSL2 では無効 or 有害）

| 設定 | 問題 |
|------|------|
| `@continuum-boot-options 'iterm'` | macOS iTerm2 専用。WSL2 では無意味 |
| `@continuum-boot 'on'` | Linux では systemd user unit を生成 (`~/.config/systemd/user/tmux.service`) |
| resurrect 保存データ | macOS/WSL 混在期の複数ウィンドウ (diary, sqm, co2 等) — 存在しないパスで `[exited]` になりうる |

### 4. `.zshrc` の macOS 依存（副次要因）

`default-shell /bin/zsh` により pane 起動時に `.zshrc` が走る。
macOS 向け `brew`, `/opt/homebrew`, Rancher Desktop 等のパスが無条件実行されている。
tmux.conf 無しでも zsh は動くが、restore 後の pane 再生成タイミングで `[exited]` に見えることがある。

---

## 現在の状態（2026-07-03 時点）

### `.tmux.conf` の有効/無効

```tmux
# 有効
set -g default-shell /bin/zsh
set -g prefix C-q
set -g mouse on
set -g default-terminal "screen-256color"
set -g terminal-overrides "xterm:colors=256"
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
run '~/.tmux/plugins/tpm/tpm'   # 1 行のみ

# 無効（コメントアウト or off）
# set -g @continuum-boot 'on'
# set -g @continuum-boot-options 'iterm'
set -g @continuum-restore 'off'
```

### resurrect 関連ファイル

```
~/.local/share/tmux/resurrect/
├── last → tmux_resurrect_20260701T193741.txt  (1018 bytes, 正常)
├── tmux_resurrect_20260702T001831.txt.broken   (0 bytes, 退避済み)
└── tmux_resurrect_*.txt                        (過去の自動保存が多数)
```

### systemd

```
~/.config/systemd/user/tmux.service  — continuum-boot 有効化時に生成された unit（現在 disabled）
```

### 動作確認コマンド

```bash
tmux kill-server && tmux          # 対話起動
tmux list-sessions                # セッション確認
wc -c ~/.local/share/tmux/resurrect/last  # last が空でないか確認
```

---

## 最終目標

> **tmux を立ち上げた段階で、前回のセッション構成（ウィンドウ・pane・cwd 等）が自動的に復元される**

これは `@continuum-restore 'on'` + tmux-resurrect の組み合わせで実現する。
現状は安定性優先で restore を off にしている。

---

## 自動復元までの道筋

### Phase 0: 現状維持（今ここ）

- [x] tmux 単体起動が安定することを確認
- [x] TPM 二重起動を解消
- [x] `@continuum-restore 'off'`
- [x] 空の resurrect ファイルを退避、`last` を正常ファイルへ修正

**確認:** `tmux kill-server && tmux` が毎回成功するか

---

### Phase 1: WSL2 用のクリーンなセッションを作る

macOS 時代の保存データは使わず、WSL2 上で新規に作り直す。

1. tmux を起動し、日常使うウィンドウ・pane 構成を整える
2. 各 pane の cwd が WSL 上の実在パスであることを確認
3. 古い保存を退避（任意）:

```bash
mkdir -p ~/.local/share/tmux/resurrect/archive
mv ~/.local/share/tmux/resurrect/tmux_resurrect_*.txt \
   ~/.local/share/tmux/resurrect/archive/ 2>/dev/null
# last シンボリックリンクも削除
rm -f ~/.local/share/tmux/resurrect/last
```

---

### Phase 2: 手動 save / restore の動作確認

自動復元の前に、resurrect 単体が WSL2 で正常動くことを確認する。

1. tmux 起動 → ウィンドウを 2〜3 個作る
2. **手動保存:** `prefix + Ctrl-s`（デフォルトキーバインド）
3. 確認:

```bash
wc -c ~/.local/share/tmux/resurrect/last   # 0 より大きいこと
head -5 ~/.local/share/tmux/resurrect/last # pane/window 行があること
```

4. `tmux kill-server`
5. tmux 再起動 → **手動復元:** `prefix + Ctrl-r`
6. ウィンドウ構成・cwd が戻るか確認

**失敗した場合のチェック:**
- pane が `[exited]` → その pane の cwd や起動コマンドが存在しない
- restore 後に zsh が即終了 → `.zshrc` の macOS 依存行を `command -v` ガードで囲む

---

### Phase 3: `.zshrc` の WSL2 対応（推奨）

restore 後の pane 再生成で zsh が落ちないよう、macOS 専用行をガードする。

対象例（`~/.zshrc`）:

```zsh
# brew — WSL にない場合はスキップ
if command -v brew &>/dev/null; then
  export GOROOT="$(brew --prefix golang 2>/dev/null)/libexec"
  ...
fi

# macOS 専用パス
[[ -d "/Applications/Visual Studio Code.app" ]] && export PATH="..."

# Rancher Desktop (macOS パス) — WSL では不要なら削除 or ガード
```

最低限、**無条件に失敗する行**（`brew --prefix` 等）を直す。

---

### Phase 4: `@continuum-restore 'on'` を再有効化

Phase 2 の手動 restore が安定してから。

1. `.tmux.conf` を変更:

```tmux
set -g @continuum-restore 'on'
```

2. 起動前に `last` が正常か確認:

```bash
wc -c ~/.local/share/tmux/resurrect/last
```

3. 安定性テスト（10 回）:

```bash
for i in $(seq 1 10); do
  tmux kill-server 2>/dev/null; sleep 0.3
  tmux new-session -d && sleep 2 && tmux list-sessions >/dev/null \
    && echo "run $i: OK" || echo "run $i: FAIL"
done
```

4. 対話起動も確認: `tmux kill-server && tmux`

**落ちる場合:**
- `touch ~/tmux_no_auto_restore` で restore を一時停止できる（continuum の公式手段）
- デバッグ: `tmux -vv 2>/tmp/tmux-debug.log` → `grep -iE 'error|resurrect|continuum' /tmp/tmux-debug.log`

---

### Phase 5: 定期自動保存の確認

`@continuum-restore 'on'` だけでは定期保存は `@continuum-save-interval` に依存（デフォルト 15 分）。

```tmux
# 任意: 保存間隔を短く（分単位）
set -g @continuum-save-interval '5'
```

保存が走っているか:

```bash
ls -lt ~/.local/share/tmux/resurrect/ | head -5
```

---

### Phase 6（任意）: ログイン時の自動 tmux 起動

WSL2 では macOS の `@continuum-boot-options 'iterm'` は **使わない**。

選択肢:

| 方法 | 内容 |
|------|------|
| A. systemd user unit | `@continuum-boot 'on'` → `~/.config/systemd/user/tmux.service` を利用。WSL2 で systemd 有効時のみ |
| B. シェル rc | `~/.zshrc` 末尾に `command -v tmux && tmux attach || tmux new`（シンプルだが nesting 注意） |
| C. Ghostty 設定 | Ghostty の `command` オプションで tmux を直接起動 |

**注意:** boot と restore を同時有効にすると、ログイン時にサーバーが既に立っている状態で `tmux` attach する流れになる。二重起動に注意。

WSL2 + Ghostty なら **C（Ghostty から tmux 起動）+ restore on** が最もシンプルな可能性が高い。

---

## トラブルシューティング早見表

| 症状 | 疑う原因 | 対処 |
|------|---------|------|
| 即 `[exited]` | zsh が pane 内で即終了 | `default-shell /bin/bash` で切り分け → `.zshrc` 修正 |
| 起動後 1〜2 秒で落ちる | `@continuum-restore` + 壊れた `last` | restore off、`wc -c last` 確認 |
| `tmux -vv` だけ動く | TPM 二重 run / restore レース | `run` 1 行に統一、restore 一時 off |
| restore 後 pane が dead | 保存時の cwd/コマンドが存在しない | WSL 上でセッション作り直し → 再 save |
| 二重 tmux | continuum-boot + 手動 tmux | boot off または attach ロジックに統一 |

---

## 参考リンク

- [tmux-continuum — automatic restore](https://github.com/tmux-plugins/tmux-continuum#automatic-restore)
- [tmux-continuum — automatic start (systemd)](https://github.com/tmux-plugins/tmux-continuum/blob/master/docs/systemd_details.md)
- [tmux-resurrect — restoring](https://github.com/tmux-plugins/tmux-resurrect/blob/master/docs/restoring_previously_saved_environment.md)
- [tmux-continuum FAQ — restore を止める](https://github.com/tmux-plugins/tmux-continuum/blob/master/docs/faq.md) (`~/tmux_no_auto_restore`)

---

## 次にやること

→ 上記 **試行手順書** の Step 0 から順に進める。
