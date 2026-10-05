#!/bin/sh
set -eu
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
rm -rf "$REPO_ROOT/kernel/build"
rm -f "$REPO_ROOT/build/janeai-initramfs.cpio.gz" "$REPO_ROOT/build/qemu-serial.log"
for name in bin sbin etc proc sys dev tmp root usr var jane init; do rm -rf "$REPO_ROOT/rootfs/$name"; done
echo 'Generated JaneAI-IOS build artifacts removed.'
