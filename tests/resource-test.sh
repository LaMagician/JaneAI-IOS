#!/bin/sh
set -eu
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
KERNEL="$REPO_ROOT/kernel/build/arch/x86/boot/bzImage"
INITRAMFS="$REPO_ROOT/build/janeai-initramfs.cpio.gz"
STATE_DISK="$REPO_ROOT/build/jane-state.img"
LOG=$(mktemp)
TIME_LOG=$(mktemp)
trap 'rm -f "$LOG" "$TIME_LOG"' EXIT HUP INT TERM

test -s "$KERNEL" && test -s "$INITRAMFS" && test -s "$STATE_DISK" || {
    echo 'Build first: ./build/build.sh' >&2
    exit 1
}
start=$(date +%s)
set +e
/usr/bin/time -o "$TIME_LOG" -f 'max_rss_kb=%M' timeout 15s qemu-system-x86_64 -m 256M \
    -kernel "$KERNEL" -initrd "$INITRAMFS" \
    -drive "file=$STATE_DISK,format=raw,if=virtio" \
    -append 'console=ttyS0 rdinit=/init' -display none -serial "file:$LOG" -monitor none -no-reboot
status=$?
set -e
elapsed=$(( $(date +%s) - start ))
[ "$status" -eq 124 ] || { cat "$LOG"; exit "$status"; }
grep -Fq 'Jane terminal ready' "$LOG" || { cat "$LOG"; exit 1; }
rss=$(awk -F= '/max_rss_kb=/ { print $2 }' "$TIME_LOG" | tail -1)
[ -n "$rss" ] && [ "$rss" -lt 524288 ] || { cat "$LOG"; exit 1; }
printf 'PASS: low-end resource test (boot_seconds=%s max_rss_kb=%s)\n' "$elapsed" "$rss"