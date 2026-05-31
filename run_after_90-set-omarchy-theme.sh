#!/bin/bash

set -euo pipefail

if ! command -v omarchy >/dev/null; then
  exit 0
fi

if ! omarchy theme list | grep -qx "Custom"; then
  exit 0
fi

if [[ $(omarchy theme current) != "Custom" ]]; then
  omarchy theme set "Custom"
fi
