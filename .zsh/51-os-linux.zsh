# Linux / WSL-specific settings

if [[ "$(uname -s)" != Linux ]]; then
  return
fi

# Cursor (WSL): Windows-side cursor CLI
cursor_win_bin="/mnt/c/Users/$USER/AppData/Local/Programs/cursor/resources/app/bin"
[[ -d "$cursor_win_bin" ]] && export PATH="$PATH:$cursor_win_bin"

if [[ -x "/mnt/c/Users/$USER/scoop/apps/cursor/current/resources/app/bin/cursor" ]]; then
  alias cursor="/mnt/c/Users/$USER/scoop/apps/cursor/current/resources/app/bin/cursor"
fi
