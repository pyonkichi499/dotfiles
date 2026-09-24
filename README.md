# dotfiles

macOS と WSL2 (Ubuntu) で共有している個人の設定ファイル。

## セットアップ

```bash
git clone git@github.com:pyonkichi499/dotfiles.git ~/dotfiles
bash ~/dotfiles/dotfilesLink.sh
```

`dotfilesLink.sh` はホームディレクトリに各設定ファイルへのシンボリックリンクを張る。
何度実行してもよい。既存の実ファイルは `*.bak` に退避してから置き換える。

## マシン固有の設定

共通設定に書けない差分は、git 管理外の `*.local` ファイルに書く。

| ファイル | 読み込み元 | 用途の例 |
|---|---|---|
| `~/.zshrc.local` | `.zsh/99-local.zsh` | マシン固有の PATH や alias |
| `~/.gitconfig.local` | `.gitconfig` の `[include]` | `core.editor`、`http.cookiefile`（例: `.gitconfig.local.example`） |

macOS では `.gitconfig.local.example` を参考に `~/.gitconfig.local` を作り、`core.editor = cursor --wait` などを設定する。

## 構成

- `.zshrc` から `.zsh/NN-*.zsh` を番号順に読み込む
  - `50-os-darwin.zsh` / `51-os-linux.zsh` に OS 固有の設定を置く
- `.gitconfig` は `~/work/private_github/` と `~/dotfiles/` の配下でだけ `.gitconfig-personal`（個人用の user と署名鍵）を読み込む
- `.codex/AGENTS.md` は AI エージェント向けの指示（リポジトリ直下の `AGENTS.md` はそこへのリンク）

## 使っているツール

必須: zsh, git, gpg（コミット署名）

あれば読み込むもの: starship, fzf, uv, fnm, bun, ghcup, cargo, gcloud, tmux (tpm), git-lfs

## 確認用コマンド

```bash
bash scripts/bench-zsh.sh   # zsh の起動時間と起動エラー
bash -ic exit               # bash の起動エラー
```
