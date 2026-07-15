#!/usr/bin/env bash
set -euo pipefail

echo "=== zsh startup benchmark ==="
echo "Date: $(date)"
echo "OS: $(uname -s) $(uname -m)"
echo

if command -v hyperfine &>/dev/null; then
  echo "[interactive]"
  hyperfine 'zsh -i -c exit' --warmup 1 --min-runs 5
  echo
  echo "[no config]"
  hyperfine 'zsh -df -c exit' --warmup 1 --min-runs 5
else
  echo "hyperfine not found; using time(1)"
  TIMEFORMAT='%R'
  echo "[interactive]"
  { time zsh -i -c exit; } 2>&1
  echo "[no config]"
  { time zsh -df -c exit; } 2>&1
fi

echo
echo "[startup errors]"
zsh -i -c 'echo OK' 2>&1 || true
