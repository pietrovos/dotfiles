#!/bin/bash

set -euo pipefail

sudo pacman -S --needed --noconfirm \
  git \
  zsh \
  kitty \
  xdg-terminal-exec \
  fzf \
  zoxide \
  wl-clipboard \
  tmux

mkdir -p "$HOME/.config" "$HOME/.oh-my-zsh/custom/plugins" "$HOME/.oh-my-zsh/custom/themes" "$HOME/.config/tmux/plugins" "$HOME/.tmux/plugins" "$HOME/.local/share/tmux/resurrect"

cat >"$HOME/.config/xdg-terminals.list" <<'EOF'
# Terminal emulator preference order for xdg-terminal-exec
# The first found and valid terminal will be used
kitty.desktop
EOF

if [[ ! -d "$HOME/.oh-my-zsh/.git" ]]; then
  rm -rf "$HOME/.oh-my-zsh"
  git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
fi

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

clone_or_update https://github.com/romkatv/powerlevel10k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
clone_or_update https://github.com/zsh-users/zsh-autosuggestions.git "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
clone_or_update https://github.com/zsh-users/zsh-completions.git "$HOME/.oh-my-zsh/custom/plugins/zsh-completions"
clone_or_update https://github.com/Aloxaf/fzf-tab.git "$HOME/.oh-my-zsh/custom/plugins/fzf-tab"
clone_or_update https://github.com/tmux-plugins/tpm.git "$HOME/.config/tmux/plugins/tpm"
clone_or_update https://github.com/tmux-plugins/tmux-resurrect.git "$HOME/.config/tmux/plugins/tmux-resurrect"
clone_or_update https://github.com/tmux-plugins/tmux-continuum.git "$HOME/.config/tmux/plugins/tmux-continuum"
clone_or_update https://github.com/tmux-plugins/tpm.git "$HOME/.tmux/plugins/tpm"
clone_or_update https://github.com/tmux-plugins/tmux-resurrect.git "$HOME/.tmux/plugins/tmux-resurrect"
clone_or_update https://github.com/tmux-plugins/tmux-continuum.git "$HOME/.tmux/plugins/tmux-continuum"

cat >"$HOME/.oh-my-zsh/custom/plugins/zsh-completions/zsh-completions.plugin.zsh" <<'EOF'
fpath+=${0:A:h}/src
EOF
