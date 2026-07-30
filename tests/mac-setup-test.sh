#!/bin/sh

set -eu

REPO_ROOT=$(cd -- "$(dirname "$0")/.." && pwd)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/mac-config-test.XXXXXX")
trap 'rm -rf "$TEST_ROOT"' EXIT HUP INT TERM

fail() {
  printf 'not ok - %s\n' "$*" >&2
  exit 1
}

assert_file() {
  [ -f "$1" ] || fail "expected file: $1"
}

assert_link() {
  [ -L "$1" ] || fail "expected symlink: $1"
}

assert_contains() {
  grep -qF "$2" "$1" || fail "expected '$2' in $1"
}

assert_not_contains() {
  if grep -qF "$2" "$1"; then
    fail "did not expect '$2' in $1"
  fi
}

HOME_DIR="$TEST_ROOT/home"
DOT_DIR="$HOME_DIR/.mac-config"
COMMAND_LOG="$TEST_ROOT/commands.log"
mkdir -p "$HOME_DIR"
cp -R "$REPO_ROOT" "$DOT_DIR"

make_stub() {
  stub_name=$1
  shift
  {
    printf '%s\n' '#!/bin/sh' 'set -eu'
    printf '%s\n' "$@"
  } >"$DOT_DIR/$stub_name"
  chmod +x "$DOT_DIR/$stub_name"
}

make_stub uname 'printf "%s\n" Darwin'
# The quoted text is the intended body of the generated command stub.
# shellcheck disable=SC2016
make_stub xcode-select \
  'if [ "${MAC_CONFIG_XCODE_MISSING:-}" = 1 ]; then' \
  '  if [ "${1:-}" = "-p" ]; then exit 1; fi' \
  '  printf "xcode-select %s\n" "$*" >>"$MAC_CONFIG_TEST_LOG"' \
  '  exit 0' \
  'fi' \
  'if [ "${1:-}" = "-p" ]; then printf "%s\n" /Library/Developer/CommandLineTools; fi'
make_stub nvim 'exit 0'
# shellcheck disable=SC2016
make_stub trash \
  'for p do' \
  '  [ -e "$p" ] || { echo "trash: $p: missing" >&2; exit 1; }' \
  '  rm -rf "$p"' \
  'done'
# The quoted text is the intended body of the generated command stub.
# shellcheck disable=SC2016
make_stub code \
  'printf "code %s\n" "$*" >>"$MAC_CONFIG_TEST_LOG"' \
  'if [ "${1:-}" = "--list-extensions" ]; then printf "%s\n" teabyii.ayu; fi'
# shellcheck disable=SC2016
make_stub kitten 'printf "kitten %s\n" "$*" >>"$MAC_CONFIG_TEST_LOG"'
# shellcheck disable=SC2016
make_stub tldr 'printf "tldr %s\n" "$*" >>"$MAC_CONFIG_TEST_LOG"'
# shellcheck disable=SC2016
make_stub brew \
  'printf "brew %s\n" "$*" >>"$MAC_CONFIG_TEST_LOG"' \
  'if [ "${1:-}" = "--prefix" ]; then printf "%s\n" /opt/homebrew; fi'
# shellcheck disable=SC2016
make_stub git \
  'printf "git %s\n" "$*" >>"$MAC_CONFIG_TEST_LOG"' \
  'if [ "${1:-}" = "clone" ]; then' \
  '  destination=' \
  '  for argument do destination=$argument; done' \
  '  mkdir -p "$destination/.git" "$destination/lua"' \
  '  printf "%s\n" "-- AstroNvim entrypoint" >"$destination/init.lua"' \
  '  printf "%s\n" "-- template community" >"$destination/lua/community.lua"' \
  'fi'

export MAC_CONFIG_TEST_LOG="$COMMAND_LOG"
export HOME="$HOME_DIR"
export XDG_DATA_HOME="$HOME_DIR/.local/share"

sh "$DOT_DIR/mac-setup" nvim >/dev/null
mkdir -p "$HOME_DIR/.config/ghostty"
printf '%s\n' 'original ghostty config' >"$HOME_DIR/.config/ghostty/config"
sh "$DOT_DIR/mac-setup" config >/dev/null

assert_file "$HOME_DIR/.config/nvim/init.lua"
assert_link "$HOME_DIR/.config/nvim/lua/community.lua"
assert_link "$HOME_DIR/.config/ghostty/config"
assert_link "$HOME_DIR/.config/kitty/kitty.conf"
assert_link "$HOME_DIR/.config/zed/settings.json"
assert_link "$HOME_DIR/Library/Application Support/Code/User/settings.json"
[ "$DOT_DIR/vscode/settings.json" -ef "$HOME_DIR/Library/Application Support/Code/User/settings.json" ] ||
  fail 'VS Code settings link does not point into vscode'
[ "$DOT_DIR/config/nvim/lua/community.lua" -ef "$HOME_DIR/.config/nvim/lua/community.lua" ] ||
  fail 'config link does not point to the repo community.lua'
backup_file=$(find "$HOME_DIR/.mac-config-backup" -type f -path '*/.config/ghostty/config' | head -n 1)
[ -n "$backup_file" ] || fail 'existing regular file was not backed up'
assert_contains "$backup_file" 'original ghostty config'
assert_contains "$HOME_DIR/.config/ghostty/config" 'font-family = JetBrainsMono Nerd Font'
assert_contains "$HOME_DIR/.config/kitty/kitty.conf" 'font_family      family="JetBrainsMono Nerd Font"'
assert_contains "$HOME_DIR/.config/zed/settings.json" '"buffer_font_family": "JetBrainsMono Nerd Font"'
assert_contains "$HOME_DIR/.config/zed/settings.json" '"font_family": "JetBrainsMono Nerd Font"'
assert_contains "$HOME_DIR/.config/herdr/config.toml" 'name = "terminal"'
assert_contains "$HOME_DIR/.config/tuicr/config.toml" 'theme = "ayu-mirage"'
assert_contains "$COMMAND_LOG" 'kitten themes --reload-in=none Ayu Mirage'

sh "$DOT_DIR/mac-setup" config >/dev/null
[ "$(grep -c 'conf.d' "$HOME_DIR/.zshrc")" = 1 ] ||
  fail 'rerunning config duplicated the zshrc snippet'

ghostty_target="$HOME_DIR/.config/ghostty/config"
rm "$ghostty_target"
mkdir "$ghostty_target"
sh "$DOT_DIR/mac-setup" config >/dev/null 2>&1 ||
  fail 'a refused directory destination should only warn'
[ -d "$ghostty_target" ] ||
  fail 'safe_ln modified a directory destination'
rmdir "$ghostty_target"
ln -s "$DOT_DIR/config/kitty/kitty.conf" "$ghostty_target"
sh "$DOT_DIR/mac-setup" config >/dev/null 2>&1 ||
  fail 'a refused conflicting symlink should only warn'
[ "$DOT_DIR/config/kitty/kitty.conf" -ef "$ghostty_target" ] ||
  fail 'safe_ln modified a conflicting symlink'
rm "$ghostty_target"
ln -s "$DOT_DIR/config/ghostty/config" "$ghostty_target"

: >"$COMMAND_LOG"
XCODE_OUTPUT="$TEST_ROOT/xcode-output.log"
MAC_CONFIG_XCODE_MISSING=1 sh "$DOT_DIR/mac-setup" config >"$XCODE_OUTPUT" 2>&1
assert_contains "$COMMAND_LOG" 'xcode-select --install'
assert_contains "$XCODE_OUTPUT" 'Complete the Xcode Command Line Tools installation, then run mac-setup again.'
assert_not_contains "$COMMAND_LOG" 'kitten themes'

: >"$COMMAND_LOG"
sh "$DOT_DIR/mac-setup" packages >/dev/null
assert_contains "$COMMAND_LOG" 'brew update'
assert_contains "$COMMAND_LOG" 'brew tap BarutSRB/tap'
assert_contains "$COMMAND_LOG" 'brew trust --cask barutsrb/tap/omniwm'
assert_contains "$COMMAND_LOG" "brew bundle --file=$DOT_DIR/Brewfile"
assert_not_contains "$COMMAND_LOG" 'brew upgrade'

: >"$COMMAND_LOG"
sh "$DOT_DIR/mac-setup" upgrade >/dev/null
assert_contains "$COMMAND_LOG" 'brew upgrade'

if sh "$DOT_DIR/mac-setup" unsupported >/dev/null 2>&1; then
  fail 'unknown command should exit non-zero'
fi

printf '%s\n' 'ok - isolated mac-setup behavior'
