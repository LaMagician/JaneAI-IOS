#!/bin/sh
set -eu
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
KERNEL="$REPO_ROOT/kernel/build/arch/x86/boot/bzImage"
INITRAMFS="$REPO_ROOT/build/janeai-initramfs.cpio.gz"
STATE_DIR="$REPO_ROOT/build/state"
test -s "$KERNEL" && test -s "$INITRAMFS" || { echo 'Build first: ./build/build.sh' >&2; exit 1; }
mkdir -p "$STATE_DIR"
exec qemu-system-x86_64 -m 256M -kernel "$KERNEL" -initrd "$INITRAMFS" -append 'console=ttyS0 rdinit=/init' -nographic -no-reboot \
  -fsdev "local,id=janestate,path=$STATE_DIR,security_model=none,readonly=off" \
  -device virtio-9p-pci,fsdev=janestate,mount_tag=janestate
