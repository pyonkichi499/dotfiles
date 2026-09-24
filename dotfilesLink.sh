#!/bin/bash
# ~/dotfiles の設定ファイルをホームディレクトリにシンボリックリンクする
# 何度実行しても同じ結果になる。既存の実ファイルは *.bak に退避する
set -euo pipefail

DOTFILES="$HOME/dotfiles"

link() {
  local src="$DOTFILES/$1" dest="$HOME/$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    mv "$dest" "$dest.bak"
    echo "backup: $dest -> $dest.bak"
  fi
  # -n: dest がディレクトリへのリンクでも、その中にリンクを作らず置き換える
  ln -sfn "$src" "$dest"
}

# shell
link .bashrc .bashrc
link .zshenv .zshenv
link .zshrc .zshrc
link .zsh .zsh   # zsh モジュール群（00-env.zsh 等）

# git
link .gitconfig .gitconfig
link .gitconfig-personal .gitconfig-personal
link .gitignore .gitignore

# LLM
link .claude/settings.json .claude/settings.json
link .claude/statusline.sh .claude/statusline.sh

# etc
link .config/starship.toml .config/starship.toml
link .config/ghostty/config .config/ghostty/config
link .customize_environment .customize_environment
link .tmux.conf .tmux.conf
link .ssh/config .ssh/config
link .vimrc .vimrc
