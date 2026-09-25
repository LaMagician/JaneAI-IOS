#!/bin/sh
set -eu
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fail() { echo "FAIL: $*" >&2; exit 1; }
sh "$REPO_ROOT/tests/daemon-integration-test.sh"
. "$REPO_ROOT/ai/permissions/permissions.sh"
. "$REPO_ROOT/ai/planner/planner.sh"
permission_check read_file /etc/hostname || fail 'safe read denied'
! permission_check read_file /etc/shadow || fail 'sensitive read allowed'
permission_check write_file /tmp/example || fail 'safe write denied'
! permission_check write_file /etc/hostname || fail 'system write allowed'
[ "$(permission_decide launch_program /bin/echo)" = 'confirm' ] || fail 'launch should require confirmation'
[ "$(permission_decide write_file /root/example)" = 'confirm' ] || fail 'root write should require confirmation'
[ "$(permission_decide change_setting hostname)" = 'confirm' ] || fail 'hostname setting should require confirmation'
[ "$(permission_decide network_request http://localhost/status)" = 'confirm' ] || fail 'localhost network should require confirmation'
[ "$(permission_decide network_request https://example.com)" = 'deny' ] || fail 'external network should be denied'
[ "$(plan_request 'read /etc/hostname')" = 'read_file|/etc/hostname|' ] || fail 'read plan invalid'
[ "$(plan_request 'processes')" = 'get_processes||' ] || fail 'process plan invalid'
[ "$(plan_request 'audit')" = 'audit||' ] || fail 'audit plan invalid'
JANE_MEMORY_FILE=$(mktemp); export JANE_MEMORY_FILE
. "$REPO_ROOT/ai/memory/memory.sh"
memory_remember color blue
[ "$(memory_recall color)" = blue ] || fail 'memory recall failed'
rm -f "$JANE_MEMORY_FILE"
JANE_STATE_DIR=$(mktemp -d); export JANE_STATE_DIR
. "$REPO_ROOT/ai/tools/tools.sh"
tool_change_setting hostname jane-test || true
[ -f "$JANE_STATE_DIR/config/settings.conf" ] || fail 'settings file not created'
grep -q '^hostname=jane-test$' "$JANE_STATE_DIR/config/settings.conf" || fail 'hostname setting not persisted'
rm -rf "$JANE_STATE_DIR"
if [ "${1:-}" = --built ]; then
  [ -x "$REPO_ROOT/rootfs/init" ] || fail '/init absent'
  [ -x "$REPO_ROOT/rootfs/bin/busybox" ] || fail 'busybox absent'
  [ -x "$REPO_ROOT/rootfs/jane/jane" ] || fail 'Jane daemon absent'
  [ -s "$REPO_ROOT/build/janeai-initramfs.cpio.gz" ] || fail 'initramfs absent'
  [ -s "$REPO_ROOT/kernel/build/arch/x86/boot/bzImage" ] || fail 'kernel absent'
  grep -q 'Jane terminal ready' "$REPO_ROOT/rootfs/jane/jane" || fail 'Jane daemon source invalid'
fi
echo 'PASS: JaneAI-IOS tests'
