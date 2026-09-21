#!/bin/sh
set -eu
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fail() { echo "FAIL: $*" >&2; exit 1; }
. "$REPO_ROOT/ai/permissions/permissions.sh"
. "$REPO_ROOT/ai/planner/planner.sh"
permission_check read_file /etc/hostname || fail 'safe read denied'
! permission_check read_file /etc/shadow || fail 'sensitive read allowed'
permission_check write_file /tmp/example || fail 'safe write denied'
! permission_check write_file /etc/hostname || fail 'system write allowed'
[ "$(plan_request 'read /etc/hostname')" = 'read_file|/etc/hostname|' ] || fail 'read plan invalid'
[ "$(plan_request 'processes')" = 'get_processes||' ] || fail 'process plan invalid'
JANE_MEMORY_FILE=$(mktemp); export JANE_MEMORY_FILE
. "$REPO_ROOT/ai/memory/memory.sh"
memory_remember color blue
[ "$(memory_recall color)" = blue ] || fail 'memory recall failed'
rm -f "$JANE_MEMORY_FILE"
if [ "${1:-}" = --built ]; then
  [ -x "$REPO_ROOT/rootfs/init" ] || fail '/init absent'
  [ -x "$REPO_ROOT/rootfs/bin/busybox" ] || fail 'busybox absent'
  [ -x "$REPO_ROOT/rootfs/jane/jane" ] || fail 'Jane daemon absent'
  [ -s "$REPO_ROOT/build/janeai-initramfs.cpio.gz" ] || fail 'initramfs absent'
  [ -s "$REPO_ROOT/kernel/build/arch/x86/boot/bzImage" ] || fail 'kernel absent'
  grep -q 'Jane terminal ready' "$REPO_ROOT/rootfs/jane/jane" || fail 'Jane daemon source invalid'
fi
echo 'PASS: JaneAI-IOS tests'
