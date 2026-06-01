#!/bin/bash

set -euo pipefail

mkdir -p "$HOME/.config/tmux/plugins" "$HOME/.tmux/plugins" "$HOME/.local/share/tmux/resurrect"

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

install_plugin() {
  local repo=$1
  local name=$2

  clone_or_update "$repo" "$HOME/.config/tmux/plugins/$name"
  clone_or_update "$repo" "$HOME/.tmux/plugins/$name"
}

install_plugin https://github.com/tmux-plugins/tpm.git tpm
install_plugin https://github.com/tmux-plugins/tmux-resurrect.git tmux-resurrect
install_plugin https://github.com/tmux-plugins/tmux-continuum.git tmux-continuum
