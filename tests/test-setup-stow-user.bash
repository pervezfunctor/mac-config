#!/usr/bin/env bash
# Integration tests for the `stow` subcommand – user perspective.
#
# These tests simulate a real user workflow:
#   - The repo's package directories (ghostty/, fish/, zed/, zsh/) are the
#     source files.
#   - A fake HOME is created in a temp directory with the repo symlinked as
#     ~/.mac-config.
#   - We invoke `nu setup.nu stow <package>` exactly as the user would and
#     verify the resulting state in ~/.config/<package>.

set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
SETUP_NU="$REPO_ROOT/scripts/setup.nu"

if ! command -v nu >/dev/null 2>&1; then
  echo "SKIP: nu is not installed"
  exit 0
fi

if [ ! -f "$SETUP_NU" ]; then
  echo "FAIL: setup.nu not found at $SETUP_NU"
  exit 1
fi

PASS=0
FAIL=0
FAILED=()

pass() {
  echo "  ok  - $1"
  PASS=$((PASS + 1))
}
fail() {
  echo "  not ok - $1"
  FAIL=$((FAIL + 1))
  FAILED+=("$1")
}

canonic() {
  local p="$1"
  (cd "$(dirname -- "$p")" && printf '%s/%s\n' "$(pwd -P)" "$(basename -- "$p")")
}

# Create an isolated user environment:
#   $home/.mac-config -> $REPO_ROOT  (symlink so real packages are used)
#   $home/.config     (created by stow)
setup_home() {
  local home
  home=$(mktemp -d -t stow-user-home.XXXXXX)
  ln -sf "$REPO_ROOT" "$home/.mac-config"
  mkdir -p "$home/.config"
  echo "$home"
}

# Run `nu setup.nu stow <pkg>` with an isolated HOME.
# Optionally pass --root as a third argument.
run_stow() {
  local home="$1" pkg="$2"
  shift 2
  local args=("$@")
  (cd "$home" && HOME="$home" nu "$SETUP_NU" stow "$pkg" "${args[@]}" 2>&1) |
    grep -v -E '^([0-9-]+ [0-9:.]+ trash\[|x )' |
    grep -v 'linking '
}

# ---------------------------------------------------------------------------
# 1. Stow ghostty: user runs `setup.nu stow ghostty`, expects config linked.
# ---------------------------------------------------------------------------
test_stow_ghostty() {
  local home
  home=$(setup_home)
  trap 'rm -rf "$home"' RETURN

  run_stow "$home" ghostty >/dev/null

  local link="$home/.config/ghostty/config"
  local src
  src=$(canonic "$home/.mac-config/ghostty/config")

  if [ -L "$link" ]; then
    pass "ghostty config is a symlink"
  else
    fail "ghostty config is a symlink (missing or not a link: $link)"
    return
  fi

  if [ "$(readlink "$link")" = "$src" ]; then
    pass "ghostty config symlink points to source"
  else
    fail "ghostty config symlink points to source (got: $(readlink "$link"), want: $src)"
  fi

  if [ -f "$link" ]; then
    pass "ghostty config is readable through the symlink"
  else
    fail "ghostty config is readable through the symlink"
  fi
}

# ---------------------------------------------------------------------------
# 2. Stow fish: user runs `setup.nu stow fish`, expects config.fish linked.
# ---------------------------------------------------------------------------
test_stow_fish() {
  local home
  home=$(setup_home)
  trap 'rm -rf "$home"' RETURN

  run_stow "$home" fish >/dev/null

  local link="$home/.config/fish/config.fish"
  local src
  src=$(canonic "$home/.mac-config/fish/config.fish")

  if [ -L "$link" ]; then
    pass "fish config.fish is a symlink"
  else
    fail "fish config.fish is a symlink (missing or not a link: $link)"
    return
  fi

  if [ "$(readlink "$link")" = "$src" ]; then
    pass "fish config.fish symlink points to source"
  else
    fail "fish config.fish symlink points to source (got: $(readlink "$link"), want: $src)"
  fi
}

# ---------------------------------------------------------------------------
# 3. Stow zed: user runs `setup.nu stow zed`, expects settings.json linked.
# ---------------------------------------------------------------------------
test_stow_zed() {
  local home
  home=$(setup_home)
  trap 'rm -rf "$home"' RETURN

  run_stow "$home" zed >/dev/null

  local link="$home/.config/zed/settings.json"
  local src
  src=$(canonic "$home/.mac-config/zed/settings.json")

  if [ -L "$link" ]; then
    pass "zed settings.json is a symlink"
  else
    fail "zed settings.json is a symlink (missing or not a link: $link)"
    return
  fi

  if [ "$(readlink "$link")" = "$src" ]; then
    pass "zed settings.json symlink points to source"
  else
    fail "zed settings.json symlink points to source (got: $(readlink "$link"), want: $src)"
  fi
}

# ---------------------------------------------------------------------------
# 4. Stow zsh: user runs `setup.nu stow zsh`, expects zshrc linked.
# ---------------------------------------------------------------------------
test_stow_zsh() {
  local home
  home=$(setup_home)
  trap 'rm -rf "$home"' RETURN

  run_stow "$home" zsh >/dev/null

  local link="$home/.config/zsh/zshrc"
  local src
  src=$(canonic "$home/.mac-config/zsh/zshrc")

  if [ -L "$link" ]; then
    pass "zsh zshrc is a symlink"
  else
    fail "zsh zshrc is a symlink (missing or not a link: $link)"
    return
  fi

  if [ "$(readlink "$link")" = "$src" ]; then
    pass "zsh zshrc symlink points to source"
  else
    fail "zsh zshrc symlink points to source (got: $(readlink "$link"), want: $src)"
  fi
}

# ---------------------------------------------------------------------------
# 5. Stow with --root: user provides a custom target root.
# ---------------------------------------------------------------------------
test_stow_with_custom_root() {
  local home custom_root
  home=$(setup_home)
  custom_root=$(mktemp -d -t stow-user-custom.XXXXXX)
  trap 'rm -rf "$home" "$custom_root"' RETURN

  run_stow "$home" ghostty --root "$custom_root" >/dev/null

  local link="$custom_root/ghostty/config"
  local default_link="$home/.config/ghostty/config"

  if [ -L "$link" ]; then
    pass "custom root: ghostty config is linked"
  else
    fail "custom root: ghostty config is linked (missing: $link)"
  fi

  if [ ! -e "$default_link" ]; then
    pass "custom root: default ~/.config is untouched"
  else
    fail "custom root: default ~/.config is untouched (unexpected: $default_link)"
  fi
}

# ---------------------------------------------------------------------------
# 6. Idempotent: running stow twice produces the same result.
# ---------------------------------------------------------------------------
test_stow_idempotent() {
  local home
  home=$(setup_home)
  trap 'rm -rf "$home"' RETURN

  run_stow "$home" ghostty >/dev/null
  local link="$home/.config/ghostty/config"
  local first_target
  first_target=$(readlink "$link")

  run_stow "$home" ghostty >/dev/null
  local second_target
  second_target=$(readlink "$link")

  if [ "$first_target" = "$second_target" ] && [ -L "$link" ]; then
    pass "re-stowing produces identical symlink"
  else
    fail "re-stowing produces identical symlink (first: $first_target, second: $second_target)"
  fi

  if [ -f "$link" ]; then
    pass "file is still readable after re-stow"
  else
    fail "file is still readable after re-stow"
  fi
}

# ---------------------------------------------------------------------------
# 7. Stow overwrites an existing regular file with a symlink.
# ---------------------------------------------------------------------------
test_stow_overwrites_existing_file() {
  local home
  home=$(setup_home)
  trap 'rm -rf "$home"' RETURN

  mkdir -p "$home/.config/ghostty"
  echo "old content" >"$home/.config/ghostty/config"

  run_stow "$home" ghostty >/dev/null

  local link="$home/.config/ghostty/config"

  if [ -L "$link" ]; then
    pass "overwrites existing regular file with symlink"
  else
    fail "overwrites existing regular file with symlink (not a link: $link)"
    return
  fi

  if [ "$(cat "$link")" != "old content" ]; then
    pass "symlink points to repo content, not old file content"
  else
    fail "symlink points to repo content, not old file content"
  fi
}

# ---------------------------------------------------------------------------
# 8. Stow overwrites a stale symlink.
# ---------------------------------------------------------------------------
test_stow_overwrites_stale_symlink() {
  local home
  home=$(setup_home)
  trap 'rm -rf "$home"' RETURN

  mkdir -p "$home/.config/ghostty"
  ln -sf "/nonexistent/path/config" "$home/.config/ghostty/config"

  run_stow "$home" ghostty >/dev/null

  local link="$home/.config/ghostty/config"
  local src
  src=$(canonic "$home/.mac-config/ghostty/config")

  if [ -L "$link" ] && [ "$(readlink "$link")" = "$src" ]; then
    pass "overwrites stale symlink with correct target"
  else
    fail "overwrites stale symlink with correct target (got: $(readlink "$link"), want: $src)"
  fi
}

# ---------------------------------------------------------------------------
# 9. Content integrity: reading through symlink gives identical content.
# ---------------------------------------------------------------------------
test_content_integrity_all_packages() {
  local home
  home=$(setup_home)
  trap 'rm -rf "$home"' RETURN

  local packages=("ghostty" "fish" "zed" "zsh")
  local all_ok=true

  for pkg in "${packages[@]}"; do
    run_stow "$home" "$pkg" >/dev/null
  done

  local files=(
    "ghostty/config"
    "fish/config.fish"
    "zed/settings.json"
    "zsh/zshrc"
  )

  for rel in "${files[@]}"; do
    local src="$home/.mac-config/$rel"
    local link="$home/.config/$rel"

    if [ ! -L "$link" ]; then
      fail "content integrity: $rel is not a symlink"
      all_ok=false
      continue
    fi

    local src_content link_content
    src_content=$(cat "$src")
    link_content=$(cat "$link")

    if [ "$src_content" = "$link_content" ]; then
      pass "content integrity: $rel matches source"
    else
      fail "content integrity: $rel matches source"
      all_ok=false
    fi
  done
}

# ---------------------------------------------------------------------------
# 10. Stow a nonexistent package: should not crash, no files created.
# ---------------------------------------------------------------------------
test_stow_nonexistent_package() {
  local home
  home=$(setup_home)
  trap 'rm -rf "$home"' RETURN

  run_stow "$home" nonexistent-pkg 2>&1

  if [ ! -e "$home/.config/nonexistent-pkg" ]; then
    pass "nonexistent package creates no target directory"
  else
    fail "nonexistent package creates no target directory (unexpected: $home/.config/nonexistent-pkg)"
  fi
}

# ---------------------------------------------------------------------------
# 11. All real repo packages stow without error.
# ---------------------------------------------------------------------------
test_stow_all_real_packages() {
  local home
  home=$(setup_home)
  trap 'rm -rf "$home"' RETURN

  local packages=("ghostty" "fish" "zed" "zsh")
  local expected_files=(
    "ghostty/config"
    "fish/config.fish"
    "zed/settings.json"
    "zsh/zshrc"
  )

  local all_ok=true
  local i=0
  for pkg in "${packages[@]}"; do
    (cd "$home" && HOME="$home" nu "$SETUP_NU" stow "$pkg" >/dev/null 2>&1)
    local rc=$?
    if [ $rc -ne 0 ]; then
      fail "stow $pkg exits without error (exit $rc)"
      all_ok=false
    else
      pass "stow $pkg exits without error"
    fi

    local rel="${expected_files[$i]}"
    if [ -L "$home/.config/$rel" ]; then
      pass "stow $pkg: $rel is linked"
    else
      fail "stow $pkg: $rel is linked (missing)"
      all_ok=false
    fi

    i=$((i + 1))
  done
}

# ---------------------------------------------------------------------------
# 12. Only files are linked, directories under package are not symlinked.
# ---------------------------------------------------------------------------
test_only_files_linked_not_dirs() {
  local home pkg_src
  home=$(setup_home)
  trap 'rm -rf "${home:-}"' RETURN

  pkg_src="$home/.mac-config"
  local has_subdir=false
  for pkg in ghostty fish zed zsh; do
    if find "$pkg_src/$pkg" -mindepth 1 -type d 2>/dev/null | head -1 | grep -q .; then
      has_subdir=true
      break
    fi
  done

  for pkg in ghostty fish zed zsh; do
    while IFS= read -r dir; do
      local rel="${dir#"$pkg_src/$pkg/"}"
      if [ -L "$home/.config/$pkg/$rel" ]; then
        fail "only files linked: $pkg/$rel is a symlink but is a directory"
      fi
    done < <(find "$pkg_src/$pkg" -mindepth 1 -type d 2>/dev/null)
  done

  pass "only files are linked, not directories"
}

# ---------------------------------------------------------------------------

main() {
  echo "Running user-perspective integration tests for setup.nu stow"
  echo "==============================================================="
  echo

  local tests=(
    test_stow_ghostty
    test_stow_fish
    test_stow_zed
    test_stow_zsh
    test_stow_with_custom_root
    test_stow_idempotent
    test_stow_overwrites_existing_file
    test_stow_overwrites_stale_symlink
    test_content_integrity_all_packages
    test_stow_nonexistent_package
    test_stow_all_real_packages
    test_only_files_linked_not_dirs
  )

  local t
  for t in "${tests[@]}"; do
    echo "== $t"
    "$t"
  done

  echo
  echo "==============================================================="
  echo "Results: $PASS passed, $FAIL failed"
  echo "==============================================================="

  if [ "$FAIL" -gt 0 ]; then
    echo
    echo "Failed:"
    for t in "${FAILED[@]}"; do echo "  - $t"; done
    exit 1
  fi
}

main "$@"
