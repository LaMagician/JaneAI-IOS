#!/bin/sh
set -eu
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fail() { echo "FAIL: $*" >&2; exit 1; }
. "$REPO_ROOT/ai/permissions/permissions.sh"

[ "$(permission_decide read_file /etc/hostname)" = 'allow' ] || fail 'hostname read should be allowed'
[ "$(permission_decide read_file ../../etc/passwd)" = 'deny' ] || fail 'relative read should be denied'
[ "$(permission_decide write_file /tmp/../etc/passwd)" = 'deny' ] || fail 'path traversal write should be denied'
[ "$(permission_decide write_file /etc/hostname)" = 'deny' ] || fail 'system write should be denied'
[ "$(permission_decide network_request http://localhost/status)" = 'confirm' ] || fail 'localhost network should require confirmation'
[ "$(permission_decide network_request http://example.com)" = 'deny' ] || fail 'external network should be denied'
[ "$(permission_decide launch_program /bin/sh)" = 'deny' ] || fail 'shell launch should be denied'

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT
printf 'secret\n' > "$WORK_DIR/secret.txt"
ln -sf "$WORK_DIR/secret.txt" "$WORK_DIR/link.txt"
[ "$(permission_decide read_file "$WORK_DIR/link.txt")" = 'allow' ] || fail 'safe symlink read inside tmp should be allowed'
ln -sf /etc/shadow "$WORK_DIR/badlink.txt"
[ "$(permission_decide read_file "$WORK_DIR/badlink.txt")" = 'deny' ] || fail 'symlink escape read should be denied'

echo 'PASS: Security hardening test'
