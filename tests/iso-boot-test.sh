#!/bin/sh
set -eu
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
ISO=${1:-"${XDG_DESKTOP_DIR:-$HOME/Desktop}/jane-ai-os-v0.1.iso"}
LOG=$(mktemp)
trap 'rm -f "$LOG"' EXIT HUP INT TERM
test -s "$ISO" || { echo "ISO not found: $ISO" >&2; exit 1; }
set +e
timeout 20s qemu-system-x86_64 -m 256M -cdrom "$ISO" -boot d \
  -display none -serial "file:$LOG" -monitor none -no-reboot
status=$?
set -e
[ "$status" -eq 124 ] || { cat "$LOG"; exit "$status"; }
for message in 'Linux version 6.12.66' 'JANEAI-IOS v0.1' '[OK] Filesystems initialized' 'Jane terminal ready'; do
  grep -Fq "$message" "$LOG" || { cat "$LOG"; echo "missing ISO boot marker: $message" >&2; exit 1; }
done
echo 'PASS: ISO boot test'