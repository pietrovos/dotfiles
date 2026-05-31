#!/bin/bash

set -euo pipefail

if ! command -v dconf >/dev/null; then
  exit 0
fi

if [[ ! -f "$HOME/.config/dconf/nautilus.conf" ]]; then
  exit 0
fi

dconf load /org/gnome/nautilus/ <"$HOME/.config/dconf/nautilus.conf"
