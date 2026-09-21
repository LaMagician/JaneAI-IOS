#!/bin/sh
set -eu
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
LOG="$REPO_ROOT/build/qemu-serial.log"
rm -f "$LOG"
printf 'status\nexit\n' | timeout 25s "$REPO_ROOT/build/run-qemu.sh" > "$LOG" 2>&1 || rc=$?
case "${rc:-0}" in 0|124) ;; *) cat "$LOG"; exit "$rc";; esac
for message in 'JANEAI-IOS v0.1' '[OK] Filesystems initialized' 'Jane terminal ready' 'Jane v0.1'; do
  grep -Fq "$message" "$LOG" || { cat "$LOG"; echo "missing boot message: $message" >&2; exit 1; }
done
echo 'PASS: QEMU boot test'
