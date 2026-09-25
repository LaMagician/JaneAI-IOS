#!/bin/sh
set -eu
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fail() { echo "FAIL: $*" >&2; exit 1; }
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT
mkdir -p "$TEST_ROOT/jane/lib"
cp "$REPO_ROOT/ai/daemon/jane.sh" "$TEST_ROOT/jane/jane"
cp "$REPO_ROOT/ai/permissions/permissions.sh" "$TEST_ROOT/jane/lib/permissions.sh"
cp "$REPO_ROOT/ai/tools/tools.sh" "$TEST_ROOT/jane/lib/tools.sh"
cp "$REPO_ROOT/ai/memory/memory.sh" "$TEST_ROOT/jane/lib/memory.sh"
cp "$REPO_ROOT/ai/planner/planner.sh" "$TEST_ROOT/jane/lib/planner.sh"
chmod +x "$TEST_ROOT/jane/jane"
JANE_STATE_DIR="$TEST_ROOT/state"; export JANE_STATE_DIR
JANE_MEMORY_FILE="$JANE_STATE_DIR/memory/facts.tsv"; export JANE_MEMORY_FILE
JANE_AUDIT_FILE="$JANE_STATE_DIR/memory/audit.log"; export JANE_AUDIT_FILE
mkdir -p "$JANE_STATE_DIR/memory" "$JANE_STATE_DIR/config"
printf 'remember color blue\nrecall color\nwrite /root/test secret\nn\nsettings hostname jane-test\ny\naudit\nexit\n' \
  | "$TEST_ROOT/jane/jane" > "$TEST_ROOT/output.log"
grep -q 'RESULT: remembered color' "$TEST_ROOT/output.log" || fail 'remember command failed'
grep -q 'RESULT: blue' "$TEST_ROOT/output.log" || fail 'recall command failed'
grep -q 'PERMISSION: denied by user for write_file /root/test' "$TEST_ROOT/output.log" || fail 'confirm deny path failed'
grep -q 'PERMISSION: allow change_setting hostname' "$TEST_ROOT/output.log" || fail 'confirm allow path failed'
grep -q 'confirm_deny' "$JANE_AUDIT_FILE" || fail 'audit missing confirm_deny'
grep -q 'confirm_allow' "$JANE_AUDIT_FILE" || fail 'audit missing confirm_allow'
grep -q '^hostname=jane-test$' "$JANE_STATE_DIR/config/settings.conf" || fail 'hostname setting persistence failed'
echo 'PASS: Jane daemon integration test'
