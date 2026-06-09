#!/usr/bin/env bash
# Integration tests for `sync.nu apply -y` and `sync.nu restore`.
#
# These tests simulate a real user workflow:
#   - The repo contains .local/bin/ and .config/ with sample files.
#   - A fake HOME is created with pre-existing files in .local/bin/ and .config/.
#   - We invoke `nu sync.nu apply -y` and verify files are synced and backed up.
#   - We then invoke `nu sync.nu restore <backup>` and verify original files return.

set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
SYNC_NU="$REPO_ROOT/scripts/sync.nu"

if ! command -v nu >/dev/null 2>&1; then
  echo "SKIP: nu is not installed"
  exit 0
fi

if [ ! -f "$SYNC_NU" ]; then
  echo "FAIL: sync.nu not found at $SYNC_NU"
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

# Create an isolated user environment with a fake repo and pre-existing files.
setup_home() {
  local home
  home=$(mktemp -d -t dotfiles-home.XXXXXX)

  # Fake repo (simulates ~/.mac-config inside the isolated home)
  mkdir -p "$home/.mac-config/.local/bin"
  mkdir -p "$home/.mac-config/.config"

  echo "#!/usr/bin/env bash" > "$home/.mac-config/.local/bin/my-script"
  echo "echo hello" >> "$home/.mac-config/.local/bin/my-script"
  chmod +x "$home/.mac-config/.local/bin/my-script"

  echo 'key = "repo-value"' > "$home/.mac-config/.config/my-app.toml"

  # Pre-existing files in home (the "old" state)
  mkdir -p "$home/.local/bin"
  mkdir -p "$home/.config"
  echo "#!/usr/bin/env bash" > "$home/.local/bin/old-script"
  echo "echo old" >> "$home/.local/bin/old-script"
  chmod +x "$home/.local/bin/old-script"
  echo 'key = "old-value"' > "$home/.config/my-app.toml"

  # A file that exists in home but NOT in the repo (should NOT be deleted by sync)
  echo "keep-me" > "$home/.config/untracked-file"

  echo "$home"
}

# ---------------------------------------------------------------------------
# 1. Sync creates backup dir with old files
# ---------------------------------------------------------------------------
test_sync_creates_backup() {
  local home
  home=$(setup_home)
  trap 'rm -rf "${home:-}"' RETURN

  DOT_DIR="$home/.mac-config" HOME="$home" nu "$SYNC_NU" apply -y >/dev/null 2>&1

  local backup_root="$home/.local/share/mac-config-backup"
  if [ -d "$backup_root" ] && [ -n "$(find "$backup_root" -maxdepth 1 -mindepth 1 -print -quit)" ]; then
    pass "sync creates backup directory with at least one timestamp"
  else
    fail "sync creates backup directory with at least one timestamp (missing: $backup_root)"
    return
  fi

  local stamp
  stamp=$(find "$backup_root" -maxdepth 1 -mindepth 1 -exec basename {} \; | sort | head -1)
  if [ ! -f "$backup_root/$stamp/.local/bin/old-script" ]; then
    pass "backup does not contain old-script (not replaced, repo lacks it)"
  else
    fail "backup does not contain old-script (not replaced, repo lacks it)"
  fi
  if [ -f "$backup_root/$stamp/.config/my-app.toml" ]; then
    pass "backup contains my-app.toml from pre-existing .config/"
  else
    fail "backup contains my-app.toml from pre-existing .config/"
  fi
}

# ---------------------------------------------------------------------------
# 2. Sync copies repo files into home
# ---------------------------------------------------------------------------
test_sync_copies_repo_files() {
  local home
  home=$(setup_home)
  trap 'rm -rf "${home:-}"' RETURN

  DOT_DIR="$home/.mac-config" HOME="$home" nu "$SYNC_NU" apply -y >/dev/null 2>&1

  if [ -f "$home/.local/bin/my-script" ]; then
    pass "sync copies my-script to .local/bin/"
  else
    fail "sync copies my-script to .local/bin/"
  fi

  if grep -q "repo-value" "$home/.config/my-app.toml" 2>/dev/null; then
    pass "sync updates my-app.toml with repo content"
  else
    fail "sync updates my-app.toml with repo content"
  fi
}

# ---------------------------------------------------------------------------
# 3. Sync does NOT delete untracked files in home
# ---------------------------------------------------------------------------
test_sync_preserves_untracked_files() {
  local home
  home=$(setup_home)
  trap 'rm -rf "${home:-}"' RETURN

  DOT_DIR="$home/.mac-config" HOME="$home" nu "$SYNC_NU" apply -y >/dev/null 2>&1

  if [ -f "$home/.config/untracked-file" ] && grep -q "keep-me" "$home/.config/untracked-file"; then
    pass "sync preserves untracked files in .config/"
  else
    fail "sync preserves untracked files in .config/"
  fi
}

# ---------------------------------------------------------------------------
# 4. Restore puts back old files from backup
# ---------------------------------------------------------------------------
test_restore_old_files() {
  local home
  home=$(setup_home)
  trap 'rm -rf "${home:-}"' RETURN

  DOT_DIR="$home/.mac-config" HOME="$home" nu "$SYNC_NU" apply -y >/dev/null 2>&1

  local backup_root="$home/.local/share/mac-config-backup"
  local stamp
  stamp=$(find "$backup_root" -maxdepth 1 -mindepth 1 -exec basename {} \; | sort | head -1)

  # Now restore
  HOME="$home" nu "$SYNC_NU" restore "$stamp" >/dev/null 2>&1

  if grep -q "old-value" "$home/.config/my-app.toml" 2>/dev/null; then
    pass "restore reverts my-app.toml to old content"
  else
    fail "restore reverts my-app.toml to old content"
  fi

  if [ -f "$home/.local/bin/old-script" ]; then
    pass "restore brings back old-script in .local/bin/"
  else
    fail "restore brings back old-script in .local/bin/"
  fi
}

# ---------------------------------------------------------------------------
# 5. Restore with nonexistent backup name fails gracefully
# ---------------------------------------------------------------------------
test_restore_bad_backup() {
  local home
  home=$(setup_home)
  trap 'rm -rf "${home:-}"' RETURN

  DOT_DIR="$home/.mac-config" HOME="$home" nu "$SYNC_NU" apply -y >/dev/null 2>&1

  local rc=0
  HOME="$home" nu "$SYNC_NU" restore "nonexistent-stamp" >/dev/null 2>&1 || rc=$?

  if [ "$rc" -ne 0 ]; then
    pass "restore with bad backup name exits with error"
  else
    fail "restore with bad backup name exits with error"
  fi
}

# ---------------------------------------------------------------------------
# 6. File permissions are preserved through sync and restore
# ---------------------------------------------------------------------------
test_permissions_preserved() {
  local home
  home=$(setup_home)
  trap 'rm -rf "${home:-}"' RETURN

  DOT_DIR="$home/.mac-config" HOME="$home" nu "$SYNC_NU" apply -y >/dev/null 2>&1

  if [ -x "$home/.local/bin/my-script" ]; then
    pass "sync preserves execute bit on my-script"
  else
    fail "sync preserves execute bit on my-script"
  fi

  local backup_root="$home/.local/share/mac-config-backup"
  local stamp
  stamp=$(find "$backup_root" -maxdepth 1 -mindepth 1 -exec basename {} \; | sort | head -1)

  HOME="$home" nu "$SYNC_NU" restore "$stamp" >/dev/null 2>&1

  if [ -x "$home/.local/bin/old-script" ]; then
    pass "restore preserves execute bit on old-script"
  else
    fail "restore preserves execute bit on old-script"
  fi
}

# ---------------------------------------------------------------------------
# 7. Nested directory structures are synced correctly
# ---------------------------------------------------------------------------
test_nested_directories() {
  local home
  home=$(setup_home)
  trap 'rm -rf "${home:-}"' RETURN

  mkdir -p "$home/.mac-config/.config/app/sub"
  echo 'nested = true' > "$home/.mac-config/.config/app/sub/deep.toml"

  DOT_DIR="$home/.mac-config" HOME="$home" nu "$SYNC_NU" apply -y >/dev/null 2>&1

  if [ -f "$home/.config/app/sub/deep.toml" ] && grep -q "nested = true" "$home/.config/app/sub/deep.toml"; then
    pass "sync copies nested repo file to .config/app/sub/deep.toml"
  else
    fail "sync copies nested repo file to .config/app/sub/deep.toml"
  fi
}

# ---------------------------------------------------------------------------
# 8. Untracked file in .local/bin/ is preserved by sync
# ---------------------------------------------------------------------------
test_sync_preserves_untracked_bin() {
  local home
  home=$(setup_home)
  trap 'rm -rf "${home:-}"' RETURN

  echo "keep-me-bin" > "$home/.local/bin/untracked-bin"

  DOT_DIR="$home/.mac-config" HOME="$home" nu "$SYNC_NU" apply -y >/dev/null 2>&1

  if [ -f "$home/.local/bin/untracked-bin" ] && grep -q "keep-me-bin" "$home/.local/bin/untracked-bin"; then
    pass "sync preserves untracked files in .local/bin/"
  else
    fail "sync preserves untracked files in .local/bin/"
  fi
}

# ---------------------------------------------------------------------------
# 9. Sync into empty home (no pre-existing .config/ or .local/bin/)
# ---------------------------------------------------------------------------
test_sync_into_empty_home() {
  local home
  home=$(mktemp -d -t dotfiles-home.XXXXXX)
  trap 'rm -rf "${home:-}"' RETURN

  mkdir -p "$home/.mac-config/.local/bin"
  mkdir -p "$home/.mac-config/.config"
  echo "#!/usr/bin/env bash" > "$home/.mac-config/.local/bin/my-script"
  echo "echo hello" >> "$home/.mac-config/.local/bin/my-script"
  chmod +x "$home/.mac-config/.local/bin/my-script"
  echo 'key = "repo-value"' > "$home/.mac-config/.config/my-app.toml"

  DOT_DIR="$home/.mac-config" HOME="$home" nu "$SYNC_NU" apply -y >/dev/null 2>&1

  if [ -f "$home/.local/bin/my-script" ]; then
    pass "sync creates .local/bin/ and copies repo file into empty home"
  else
    fail "sync creates .local/bin/ and copies repo file into empty home"
  fi

  if [ -f "$home/.config/my-app.toml" ] && grep -q "repo-value" "$home/.config/my-app.toml"; then
    pass "sync creates .config/ and copies repo file into empty home"
  else
    fail "sync creates .config/ and copies repo file into empty home"
  fi
}

# ---------------------------------------------------------------------------
# 10. Restore reverts post-sync file edits
# ---------------------------------------------------------------------------
test_restore_reverts_edits() {
  local home
  home=$(setup_home)
  trap 'rm -rf "${home:-}"' RETURN

  DOT_DIR="$home/.mac-config" HOME="$home" nu "$SYNC_NU" apply -y >/dev/null 2>&1

  echo 'key = "modified-after-sync"' > "$home/.config/my-app.toml"

  local backup_root="$home/.local/share/mac-config-backup"
  local stamp
  stamp=$(find "$backup_root" -maxdepth 1 -mindepth 1 -exec basename {} \; | sort | head -1)

  HOME="$home" nu "$SYNC_NU" restore "$stamp" >/dev/null 2>&1

  if grep -q "old-value" "$home/.config/my-app.toml" 2>/dev/null; then
    pass "restore reverts file edited after sync back to backup content"
  else
    fail "restore reverts file edited after sync back to backup content"
  fi
}

# ---------------------------------------------------------------------------
# 11. Post-sync new file survives restore (rsync without --delete)
# ---------------------------------------------------------------------------
test_restore_preserves_new_files() {
  local home
  home=$(setup_home)
  trap 'rm -rf "${home:-}"' RETURN

  DOT_DIR="$home/.mac-config" HOME="$home" nu "$SYNC_NU" apply -y >/dev/null 2>&1

  echo "created-after-sync" > "$home/.config/new-file.toml"

  local backup_root="$home/.local/share/mac-config-backup"
  local stamp
  stamp=$(find "$backup_root" -maxdepth 1 -mindepth 1 -exec basename {} \; | sort | head -1)

  HOME="$home" nu "$SYNC_NU" restore "$stamp" >/dev/null 2>&1

  if [ -f "$home/.config/new-file.toml" ] && grep -q "created-after-sync" "$home/.config/new-file.toml"; then
    pass "restore does not delete files created after sync"
  else
    fail "restore does not delete files created after sync"
  fi
}

# ---------------------------------------------------------------------------
# 12. Restore fails when no backup directory exists
# ---------------------------------------------------------------------------
test_restore_no_backup_dir() {
  local home
  home=$(mktemp -d -t dotfiles-home.XXXXXX)
  trap 'rm -rf "${home:-}"' RETURN

  local rc=0
  HOME="$home" nu "$SYNC_NU" restore >/dev/null 2>&1 || rc=$?

  if [ "$rc" -ne 0 ]; then
    pass "restore fails when backup directory does not exist"
  else
    fail "restore fails when backup directory does not exist"
  fi
}

# ---------------------------------------------------------------------------
# 13. Restore fails when backup directory is empty
# ---------------------------------------------------------------------------
test_restore_empty_backup_dir() {
  local home
  home=$(setup_home)
  trap 'rm -rf "${home:-}"' RETURN

  mkdir -p "$home/.local/share/mac-config-backup"

  local rc=0
  HOME="$home" nu "$SYNC_NU" restore >/dev/null 2>&1 || rc=$?

  if [ "$rc" -ne 0 ]; then
    pass "restore fails when backup directory is empty"
  else
    fail "restore fails when backup directory is empty"
  fi
}

# ---------------------------------------------------------------------------
# 14. Restore rejects a non-directory backup entry
# ---------------------------------------------------------------------------
test_restore_rejects_file_as_backup() {
  local home
  home=$(setup_home)
  trap 'rm -rf "${home:-}"' RETURN

  mkdir -p "$home/.local/share/mac-config-backup"
  echo "not-a-dir" > "$home/.local/share/mac-config-backup/fake-backup"

  local rc=0
  HOME="$home" nu "$SYNC_NU" restore "fake-backup" >/dev/null 2>&1 || rc=$?

  if [ "$rc" -ne 0 ]; then
    pass "restore rejects a file passed as backup name"
  else
    fail "restore rejects a file passed as backup name"
  fi
}

# ---------------------------------------------------------------------------
# 15. Restore works with partial backup (missing .local/bin/)
# ---------------------------------------------------------------------------
test_restore_partial_backup() {
  local home
  home=$(setup_home)
  trap 'rm -rf "${home:-}"' RETURN

  DOT_DIR="$home/.mac-config" HOME="$home" nu "$SYNC_NU" apply -y >/dev/null 2>&1

  local backup_root="$home/.local/share/mac-config-backup"
  local stamp
  stamp=$(find "$backup_root" -maxdepth 1 -mindepth 1 -exec basename {} \; | sort | head -1)

  rm -rf "$backup_root/$stamp/.local"

  HOME="$home" nu "$SYNC_NU" restore "$stamp" >/dev/null 2>&1

  if grep -q "old-value" "$home/.config/my-app.toml" 2>/dev/null; then
    pass "restore with partial backup still restores .config/"
  else
    fail "restore with partial backup still restores .config/"
  fi
}

# ---------------------------------------------------------------------------
# 16. Restore creates a pre-restore backup of current state
# ---------------------------------------------------------------------------
test_restore_creates_pre_backup() {
  local home
  home=$(setup_home)
  trap 'rm -rf "${home:-}"' RETURN

  DOT_DIR="$home/.mac-config" HOME="$home" nu "$SYNC_NU" apply -y >/dev/null 2>&1

  local backup_root="$home/.local/share/mac-config-backup"
  local stamp
  stamp=$(find "$backup_root" -maxdepth 1 -mindepth 1 -exec basename {} \; | sort | head -1)

  HOME="$home" nu "$SYNC_NU" restore "$stamp" >/dev/null 2>&1

  local pre_restore_count
  pre_restore_count=$(find "$backup_root" -maxdepth 1 -name "pre-restore-*" -exec basename {} \; | grep -c .)

  if [ "$pre_restore_count" -ge 1 ]; then
    pass "restore creates a pre-restore backup"
  else
    fail "restore creates a pre-restore backup"
  fi

  local pre_stamp
  pre_stamp=$(find "$backup_root" -maxdepth 1 -name "pre-restore-*" -exec basename {} \; | sort | head -1)
  if [ -f "$backup_root/$pre_stamp/.config/my-app.toml" ] && grep -q "repo-value" "$backup_root/$pre_stamp/.config/my-app.toml"; then
    pass "pre-restore backup contains current state (repo content)"
  else
    fail "pre-restore backup contains current state (repo content)"
  fi
}

# ---------------------------------------------------------------------------
# 17. Sync is idempotent — running twice doesn't clobber backups
# ---------------------------------------------------------------------------
test_sync_idempotent() {
  local home
  home=$(setup_home)
  trap 'rm -rf "${home:-}"' RETURN

  DOT_DIR="$home/.mac-config" HOME="$home" nu "$SYNC_NU" apply -y >/dev/null 2>&1
  DOT_DIR="$home/.mac-config" HOME="$home" nu "$SYNC_NU" apply -y >/dev/null 2>&1

  local backup_root="$home/.local/share/mac-config-backup"
  local count
  count=$(find "$backup_root" -maxdepth 1 -mindepth 1 2>/dev/null | wc -l)

  if [ "$count" -ge 2 ]; then
    pass "idempotent: two sync runs create two timestamps"
  else
    fail "idempotent: two sync runs create two timestamps (got $count)"
  fi

  if grep -q "repo-value" "$home/.config/my-app.toml" 2>/dev/null; then
    pass "idempotent: repo content still in place after second sync"
  else
    fail "idempotent: repo content still in place after second sync"
  fi
}

# ---------------------------------------------------------------------------

main() {
  echo "Running integration tests for dotfiles sync -y and restore"
  echo "======================================================="
  echo

  local tests=(
    test_sync_creates_backup
    test_sync_copies_repo_files
    test_sync_preserves_untracked_files
    test_restore_old_files
    test_restore_bad_backup
    test_permissions_preserved
    test_nested_directories
    test_sync_preserves_untracked_bin
    test_sync_into_empty_home
    test_restore_reverts_edits
    test_restore_preserves_new_files
    test_restore_no_backup_dir
    test_restore_empty_backup_dir
    test_restore_rejects_file_as_backup
    test_restore_partial_backup
    test_restore_creates_pre_backup
    test_sync_idempotent
  )

  local t
  for t in "${tests[@]}"; do
    echo "== $t"
    "$t"
  done

  echo
  echo "======================================================="
  echo "Results: $PASS passed, $FAIL failed"
  echo "======================================================="

  if [ "$FAIL" -gt 0 ]; then
    echo
    echo "Failed:"
    for t in "${FAILED[@]}"; do echo "  - $t"; done
    exit 1
  fi
}

main "$@"
