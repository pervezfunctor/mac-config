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
  'if [ "${1:-}" = "--list-extensions" ]; then printf "%s\n" catppuccin.catppuccin-vsc; fi'
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
sh "$DOT_DIR/mac-setup" config >/dev/null

assert_file "$HOME_DIR/.config/nvim/init.lua"
cmp "$DOT_DIR/config/nvim/lua/community.lua" "$HOME_DIR/.config/nvim/lua/community.lua" >/dev/null ||
  fail 'config sync did not overlay the repo community.lua over the template copy'
assert_contains "$COMMAND_LOG" 'kitten themes --reload-in=none Catppuccin-Mocha'

sh "$DOT_DIR/mac-setup" config >/dev/null
[ "$(grep -c 'conf.d' "$HOME_DIR/.zshrc")" = 1 ] ||
  fail 'rerunning config duplicated the zshrc snippet'

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
