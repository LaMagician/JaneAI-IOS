#!/bin/sh
set -eu
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
ROOTFS="$REPO_ROOT/rootfs"
BROKEN_INITRAMFS="$REPO_ROOT/build/janeai-initramfs-broken.cpio.gz"
LOG="$REPO_ROOT/build/qemu-recovery.log"
KERNEL="$REPO_ROOT/kernel/build/arch/x86/boot/bzImage"
rm -f "$BROKEN_INITRAMFS" "$LOG"
test -s "$KERNEL" || { echo 'Kernel missing; run ./build/build.sh first' >&2; exit 1; }

cp -a "$ROOTFS" "$REPO_ROOT/build/rootfs-broken"
rm -f "$REPO_ROOT/build/rootfs-broken/jane/jane"
(cd "$REPO_ROOT/build/rootfs-broken" && find . -print | LC_ALL=C sort | cpio --quiet -o -H newc | gzip -n > "$BROKEN_INITRAMFS")
rm -rf "$REPO_ROOT/build/rootfs-broken"

printf 'exit\n' | timeout 25s qemu-system-x86_64 -m 256M -kernel "$KERNEL" -initrd "$BROKEN_INITRAMFS" -append 'console=ttyS0 rdinit=/init' -nographic -no-reboot > "$LOG" 2>&1 || rc=$?
case "${rc:-0}" in 0|124) ;; *) cat "$LOG"; exit "$rc";; esac

grep -Fq '[ERROR] Jane daemon unavailable; opening recovery shell' "$LOG" || { cat "$LOG"; echo 'recovery shell fallback message missing' >&2; exit 1; }
echo 'PASS: QEMU recovery test'
