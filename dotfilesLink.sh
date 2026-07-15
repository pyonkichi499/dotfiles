#!/bin/bash
# shell
ln -sf ~/dotfiles/.bashrc ~/.bashrc
ln -sf ~/dotfiles/.zshenv ~/.zshenv
ln -sf ~/dotfiles/.zshrc ~/.zshrc
ln -sf ~/dotfiles/.zsh ~/.zsh   # zsh モジュール群（00-env.zsh 等）

# git
ln -sf ~/dotfiles/.gitconfig ~/.gitconfig
ln -sf ~/dotfiles/.gitconfig-personal ~/.gitconfig-personal
ln -sf ~/dotfiles/.gitignore ~/.gitignore

# LLM
ln -sf ~/dotfiles/.claude/settings.json ~/.claude/settings.json
ln -sf ~/dotfiles/.claude/statusline.sh ~/.claude/statusline.sh
ln -sf ~/dotfiles/.codex/AGENTS.md ~/dotfiles/AGENTS.md

# etc
ln -sf ~/dotfiles/.config/starship.toml ~/.config/starship.toml
ln -sf ~/dotfiles/.config/ghostty/config ~/.config/ghostty/config
ln -sf ~/dotfiles/.customize_environment ~/.customize_environment
ln -sf ~/dotfiles/.tmux.conf ~/.tmux.conf
ln -sf ~/dotfiles/.ssh/config ~/.ssh/config
ln -sf ~/dotfiles/.vimrc ~/.vimrc
