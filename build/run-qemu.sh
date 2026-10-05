#!/bin/sh
set -eu
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
KERNEL="$REPO_ROOT/kernel/build/arch/x86/boot/bzImage"
INITRAMFS="$REPO_ROOT/build/janeai-initramfs.cpio.gz"
STATE_DISK="$REPO_ROOT/build/jane-state.img"
test -s "$KERNEL" && test -s "$INITRAMFS" || { echo 'Build first: ./build/build.sh' >&2; exit 1; }
"$REPO_ROOT/build/build-state-disk.sh" "$STATE_DISK" >/dev/null
exec qemu-system-x86_64 -m 256M -kernel "$KERNEL" -initrd "$INITRAMFS" -drive "file=$STATE_DISK,format=raw,if=virtio" -append 'console=ttyS0 rdinit=/init' -nographic -no-reboot
