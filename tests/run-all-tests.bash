#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

pass=0
fail=0
failed=()

for test_file in "$SCRIPT_DIR"/test-*.bash; do
  [ -f "$test_file" ] || continue
  echo "== Running $(basename "$test_file")"
  if bash "$test_file"; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    failed+=("$(basename "$test_file")")
  fi
  echo
done

echo "==============================="
echo "Suites: $pass passed, $fail failed"
echo "==============================="

if [ "$fail" -gt 0 ]; then
  echo "Failed:"
  for t in "${failed[@]}"; do echo "  - $t"; done
  exit 1
fi
