# zsh entry point — modules live in ~/.zsh/

ZSH_CONFIG_DIR="${ZDOTDIR:-$HOME}/.zsh"

for f in \
  00-env \
  10-path \
  20-aliases \
  30-completion \
  40-tools \
  50-os-darwin \
  51-os-linux \
  60-prompt \
  99-local
do
  [[ -f "$ZSH_CONFIG_DIR/$f.zsh" ]] && source "$ZSH_CONFIG_DIR/$f.zsh"
done
