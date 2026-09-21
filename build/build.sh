#!/bin/sh
set -eu
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
for command in gcc make git qemu-system-x86_64 busybox cpio xz gzip; do command -v "$command" >/dev/null || { echo "missing required dependency: $command" >&2; exit 1; }; done
"$REPO_ROOT/build/build-kernel.sh"
"$REPO_ROOT/build/build-rootfs.sh"
"$REPO_ROOT/tests/run-tests.sh" --built
echo 'JaneAI-IOS v0.1 build completed successfully.'
