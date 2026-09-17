#!/usr/bin/env bash
set -euo pipefail

repo="${HOME}/projects/opencode-custom"
remote="https://github.com/pietrovos/opencode.git"
branch="custom-tui"

if [[ -d "${repo}/.git" ]]; then
  if ! git -C "${repo}" remote get-url pietrovos >/dev/null 2>&1; then
    git -C "${repo}" remote add pietrovos "${remote}"
  fi
  git -C "${repo}" fetch pietrovos "${branch}"
  git -C "${repo}" switch "${branch}"
  git -C "${repo}" pull --ff-only pietrovos "${branch}"
else
  git clone --branch "${branch}" "${remote}" "${repo}"
fi

mise install bun@1.3.14
mise exec bun@1.3.14 -- bun --cwd "${repo}" install
mise exec bun@1.3.14 -- bun --cwd "${repo}/packages/opencode" run build --single
