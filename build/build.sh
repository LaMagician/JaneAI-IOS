#!/bin/sh
set -eu
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
for command in gcc make curl busybox cpio xz gzip; do command -v "$command" >/dev/null || { echo "missing required dependency: $command" >&2; exit 1; }; done
"$REPO_ROOT/build/build-kernel.sh"
"$REPO_ROOT/build/build-rootfs.sh"
"$REPO_ROOT/tests/run-tests.sh" --built
if command -v qemu-system-x86_64 >/dev/null; then
  "$REPO_ROOT/tests/qemu-boot-test.sh"
else
  echo '[WARN] qemu-system-x86_64 not found; skipped QEMU boot smoke test'
fi
echo 'JaneAI-IOS v0.1 build completed successfully.'
