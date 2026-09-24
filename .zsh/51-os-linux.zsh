# Linux / WSL-specific settings

if [[ "$(uname -s)" != Linux ]]; then
  return
fi

# Cursor CLI is provided through the Windows PATH inherited by WSL.
