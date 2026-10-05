#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUTPUT=${1:-"$REPO_ROOT/build/jane-state.img"}
SIZE=${JANE_STATE_SIZE:-64M}

for command in truncate mkfs.ext4; do
  command -v "$command" >/dev/null || {
    echo "missing required dependency: $command" >&2
    exit 1
  }
done

mkdir -p "$(dirname -- "$OUTPUT")"
if [ ! -s "$OUTPUT" ]; then
  truncate -s "$SIZE" "$OUTPUT"
  mkfs.ext4 -F -q -L JANE_STATE "$OUTPUT"
  chmod 0600 "$OUTPUT"
  echo "State disk created: $OUTPUT ($SIZE)"
else
  echo "State disk preserved: $OUTPUT"
fi