#!/bin/bash

set -euo pipefail

if ! command -v omarchy-theme-set >/dev/null; then
  exit 0
fi

if [[ ! -d "$HOME/.config/omarchy/themes/custom" ]]; then
  exit 0
fi

if [[ ! -f "$HOME/.config/omarchy/current/theme.name" ]] || [[ $(<"$HOME/.config/omarchy/current/theme.name") != "custom" ]]; then
  omarchy-theme-set custom
fi
