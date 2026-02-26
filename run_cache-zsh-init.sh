#!/bin/bash
# Regenerate cached zsh init scripts on every chezmoi apply.
# The zshrc sources these cached files instead of running subprocesses on every shell startup.

set -euo pipefail

CACHE_DIR="$HOME/.cache/zsh"
mkdir -p "$CACHE_DIR"

if command -v fzf &>/dev/null; then
  fzf --zsh > "$CACHE_DIR/fzf.zsh"
fi

if command -v zoxide &>/dev/null; then
  zoxide init zsh > "$CACHE_DIR/zoxide.zsh"
fi
