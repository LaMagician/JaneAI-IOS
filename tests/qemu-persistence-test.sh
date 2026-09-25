#!/bin/sh
set -eu
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
STATE_DIR="$REPO_ROOT/build/state"
LOG1="$REPO_ROOT/build/qemu-persist-1.log"
LOG2="$REPO_ROOT/build/qemu-persist-2.log"
rm -f "$LOG1" "$LOG2"
rm -rf "$STATE_DIR"
mkdir -p "$STATE_DIR"

printf 'remember bootkey persistent\nexit\n' | timeout 30s "$REPO_ROOT/build/run-qemu.sh" > "$LOG1" 2>&1 || rc=$?
case "${rc:-0}" in 0|124) ;; *) cat "$LOG1"; exit "$rc";; esac

printf 'recall bootkey\nexit\n' | timeout 30s "$REPO_ROOT/build/run-qemu.sh" > "$LOG2" 2>&1 || rc=$?
case "${rc:-0}" in 0|124) ;; *) cat "$LOG2"; exit "$rc";; esac

grep -Fq 'RESULT: persistent' "$LOG2" || { cat "$LOG2"; echo 'persistent memory recall failed' >&2; exit 1; }
echo 'PASS: QEMU persistence test'
