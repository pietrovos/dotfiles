#!/bin/bash

set -euo pipefail

if ! command -v nvim >/dev/null; then
  exit 0
fi

if [[ ! -f "$HOME/.config/nvim/lazy-lock.json" ]]; then
  exit 0
fi

nvim --headless "+Lazy! sync" +qa
