#!/bin/sh

set -eu

REPO_ROOT=$(cd -- "$(dirname "$0")/.." && pwd)

sh "$REPO_ROOT/tests/mac-setup-test.sh"
sh "$REPO_ROOT/tests/config-test.sh"
