#!/bin/sh

set -eu

REPO_ROOT=$(cd -- "$(dirname "$0")/.." && pwd)

fail() {
  printf 'not ok - %s\n' "$*" >&2
  exit 1
}

zsh -n "$REPO_ROOT/config/zsh/conf.d/custom.zsh" || fail 'zsh config has syntax errors'

if command -v fish >/dev/null 2>&1; then
  fish --no-config -c "source '$REPO_ROOT/config/fish/conf.d/custom.fish'" >/dev/null ||
    fail 'fish config fails to source'
fi

printf '%s\n' 'ok - shell configs are valid'
