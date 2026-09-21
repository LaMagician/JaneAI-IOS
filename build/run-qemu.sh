#!/bin/sh
set -eu
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
KERNEL="$REPO_ROOT/kernel/build/arch/x86/boot/bzImage"
INITRAMFS="$REPO_ROOT/build/janeai-initramfs.cpio.gz"
test -s "$KERNEL" && test -s "$INITRAMFS" || { echo 'Build first: ./build/build.sh' >&2; exit 1; }
exec qemu-system-x86_64 -m 256M -kernel "$KERNEL" -initrd "$INITRAMFS" -append 'console=ttyS0 rdinit=/init' -nographic -no-reboot
