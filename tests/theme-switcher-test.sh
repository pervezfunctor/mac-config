#!/bin/sh

set -eu

REPO_ROOT=$(cd -- "$(dirname "$0")/.." && pwd)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/theme-switcher-test.XXXXXX")
trap 'rm -rf "$TEST_ROOT"' EXIT HUP INT TERM

fail() {
  printf 'not ok - %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  grep -qF "$2" "$1" || fail "expected '$2' in $1"
}

CONFIG_ROOT="$TEST_ROOT/repo"
BIN_DIR="$TEST_ROOT/bin"
COMMAND_LOG="$TEST_ROOT/commands.log"
HOME_DIR="$TEST_ROOT/home"
mkdir -p \
  "$CONFIG_ROOT" \
  "$BIN_DIR" \
  "$HOME_DIR/.config/kitty" \
  "$HOME_DIR/Library/Application Support/Cursor/User" \
  "$HOME_DIR/Library/Application Support/Code/User"
cp -R "$REPO_ROOT/." "$CONFIG_ROOT/"
printf '%s\n' 'background #000000' >"$HOME_DIR/.config/kitty/current-theme.conf"
printf '%s\n' '{"window.autoDetectColorScheme": true}' \
  >"$HOME_DIR/Library/Application Support/Cursor/User/settings.json"
cp "$CONFIG_ROOT/vscode/settings.json" \
  "$HOME_DIR/Library/Application Support/Code/User/settings.json"

make_stub() {
  name=$1
  shift
  {
    printf '%s\n' '#!/bin/sh' 'set -eu'
    printf '%s\n' "$@"
  } >"$BIN_DIR/$name"
  chmod +x "$BIN_DIR/$name"
}

# shellcheck disable=SC2016
make_stub kitten \
  'printf "kitten %s\n" "$*" >>"$THEME_TEST_LOG"' \
  'printf "%s\n" "background #282c34" "foreground #abb2bf"'
# shellcheck disable=SC2016
make_stub code \
  'if [ "${1:-}" = "--list-extensions" ]; then printf "%s\n" zhuangtongfa.Material-theme; fi'
# shellcheck disable=SC2016
make_stub cursor \
  'if [ "${1:-}" = "--list-extensions" ]; then printf "%s\n" zhuangtongfa.Material-theme; fi'
# Avoid interacting with a real Herdr server during the isolated test.
make_stub herdr 'exit 0'

export PATH="$BIN_DIR:$PATH"
export HOME="$HOME_DIR"
export XDG_CONFIG_HOME="$HOME_DIR/.config"
export THEME_TEST_LOG="$COMMAND_LOG"
export THEME_SWITCHER_ROOT="$CONFIG_ROOT"
export THEME_SWITCHER_NO_RELOAD=1

"$CONFIG_ROOT/theme-switcher" --theme 'One Dark' >/dev/null

assert_contains "$CONFIG_ROOT/.theme-current" 'One Dark'
assert_contains "$CONFIG_ROOT/config/ghostty/config" 'theme = Atom One Dark'
assert_contains "$CONFIG_ROOT/config/kitty/kitty.conf" '# One Dark'
assert_contains "$CONFIG_ROOT/config/kitty/current-theme.conf" 'background #282c34'
assert_contains "$CONFIG_ROOT/config/zed/settings.json" '"dark": "One Dark"'
assert_contains "$CONFIG_ROOT/vscode/settings.json" '"workbench.colorTheme": "One Dark Pro"'
assert_contains "$CONFIG_ROOT/cursor/settings.json" '"workbench.colorTheme": "One Dark Pro"'
assert_contains "$CONFIG_ROOT/cursor/settings.json" '"window.autoDetectColorScheme": false'
assert_contains "$HOME_DIR/Library/Application Support/Cursor/User/settings.json" '"workbench.colorTheme": "One Dark Pro"'
assert_contains "$HOME_DIR/Library/Application Support/Cursor/User/settings.json" '"window.autoDetectColorScheme": false'
assert_contains "$HOME_DIR/.config/kitty/current-theme.conf" 'background #282c34'
assert_contains "$CONFIG_ROOT/config/tuicr/config.toml" 'theme = "onedark"'
assert_contains "$CONFIG_ROOT/config/herdr/config.toml" 'name = "one-dark"'
assert_contains "$CONFIG_ROOT/config/nvim/lua/theme.lua" '"navarasu/onedark.nvim"'
assert_contains "$COMMAND_LOG" 'kitten themes --dump-theme One Dark'

checksums_before=$(find "$CONFIG_ROOT" -type f -not -path '*/__pycache__/*' -exec cksum {} \; | sort)
"$CONFIG_ROOT/theme-switcher" --theme 'One Dark' >/dev/null
checksums_after=$(find "$CONFIG_ROOT" -type f -not -path '*/__pycache__/*' -exec cksum {} \; | sort)
[ "$checksums_before" = "$checksums_after" ] || fail 'rerunning the same theme changed files'

"$CONFIG_ROOT/theme-switcher" --theme 'Catppuccin Frappé' >/dev/null
assert_contains "$CONFIG_ROOT/config/ghostty/config" 'theme = Catppuccin Frappe'
assert_contains "$CONFIG_ROOT/config/kitty/kitty.conf" '# Catppuccin-Frappe'
assert_contains "$CONFIG_ROOT/config/zed/settings.json" '"catppuccin": true'
assert_contains "$CONFIG_ROOT/config/zed/settings.json" '"dark": "Catppuccin Frappé"'
assert_contains "$CONFIG_ROOT/vscode/settings.json" '"workbench.colorTheme": "Catppuccin Frappé"'
assert_contains "$CONFIG_ROOT/config/tuicr/config.toml" 'theme = "catppuccin-frappe"'
assert_contains "$CONFIG_ROOT/config/herdr/config.toml" 'name = "terminal"'
assert_contains "$CONFIG_ROOT/config/nvim/lua/theme.lua" 'colorscheme = "catppuccin-frappe"'

"$CONFIG_ROOT/theme-switcher" --theme 'Tokyo Night Storm' >/dev/null
assert_contains "$CONFIG_ROOT/config/ghostty/config" 'theme = TokyoNight Storm'
assert_contains "$CONFIG_ROOT/config/kitty/kitty.conf" '# Tokyo Night Storm'
assert_contains "$CONFIG_ROOT/config/zed/settings.json" '"tokyo-night": true'
assert_contains "$CONFIG_ROOT/config/zed/settings.json" '"dark": "Tokyo Night Storm"'
assert_contains "$CONFIG_ROOT/vscode/settings.json" '"workbench.colorTheme": "Tokyo Night Storm"'
assert_contains "$CONFIG_ROOT/cursor/settings.json" '"workbench.colorTheme": "Tokyo Night Storm"'
assert_contains "$HOME_DIR/Library/Application Support/Cursor/User/settings.json" '"workbench.colorTheme": "Tokyo Night Storm"'
assert_contains "$CONFIG_ROOT/config/tuicr/config.toml" 'theme = "tokyo-night-storm"'
assert_contains "$CONFIG_ROOT/config/herdr/config.toml" 'name = "tokyo-night"'
assert_contains "$CONFIG_ROOT/config/nvim/lua/theme.lua" 'colorscheme = "tokyonight-storm"'
assert_contains "$CONFIG_ROOT/config/nvim/lua/theme.lua" '"folke/tokyonight.nvim"'

if "$CONFIG_ROOT/theme-switcher" --theme 'Not A Theme' >/dev/null 2>&1; then
  fail 'unknown theme should exit non-zero'
fi

printf '%s\n' 'ok - theme switcher is coordinated and idempotent'
