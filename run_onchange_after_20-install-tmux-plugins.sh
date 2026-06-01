#!/bin/bash

set -euo pipefail

mkdir -p "$HOME/.tmux/plugins" "$HOME/.local/share/tmux/resurrect"

clone_or_update() {
  local repo=$1
  local dest=$2

  if [[ -d "$dest/.git" ]]; then
    git -C "$dest" pull --ff-only
  else
    rm -rf "$dest"
    git clone --depth 1 "$repo" "$dest"
  fi
}

clone_or_update https://github.com/tmux-plugins/tpm.git "$HOME/.tmux/plugins/tpm"
clone_or_update https://github.com/tmux-plugins/tmux-resurrect.git "$HOME/.tmux/plugins/tmux-resurrect"
clone_or_update https://github.com/tmux-plugins/tmux-continuum.git "$HOME/.tmux/plugins/tmux-continuum"
