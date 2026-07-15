# macOS-specific settings

if [[ "$(uname -s)" != Darwin ]]; then
  return
fi

# Homebrew
if command -v brew &>/dev/null; then
  eval "$(brew shellenv)"
  if brew --prefix golang &>/dev/null; then
    export GOROOT="$(brew --prefix golang)/libexec"
    export PATH="$PATH:${GOROOT}/bin"
  fi
elif [[ "$(uname -m)" == arm64 && -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

export LDFLAGS="-L/opt/homebrew/opt/zlib/lib"
export CPPFLAGS="-I/opt/homebrew/opt/zlib/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/zlib/lib/pkgconfig"

export PATH="/opt/homebrew/bin:$PATH"
export PATH="/usr/local/opt/ncurses/bin:$PATH"
export PATH="/usr/local/opt/openjdk/bin:$PATH"
export CPPFLAGS="-I/usr/local/opt/openjdk/include"

# Rancher Desktop
[[ -d "$HOME/.rd/bin" ]] && export PATH="$HOME/.rd/bin:$PATH"

# VS Code
[[ -d "/Applications/Visual Studio Code.app" ]] &&
  export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

# Java
[[ -d "$HOME/Library/Java/JavaVirtualMachines/adopt-openjdk-11.0.11/Contents/Home" ]] &&
  export JAVA_HOME="$HOME/Library/Java/JavaVirtualMachines/adopt-openjdk-11.0.11/Contents/Home"

# iTerm2 shell integration
[[ -f "$HOME/.iterm2_shell_integration.zsh" ]] && source "$HOME/.iterm2_shell_integration.zsh"

# Rosetta / Apple Silicon
alias x86='arch -x86_64 zsh'
alias arm='arch -arm64e zsh'
