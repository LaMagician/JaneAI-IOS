#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
VERSION=${JANE_VERSION:-v0.1}
DESKTOP=${XDG_DESKTOP_DIR:-"$HOME/Desktop"}
OUTPUT=${1:-"$DESKTOP/jane-ai-os-$VERSION"}
ISO="$OUTPUT/jane-ai-os-$VERSION.iso"

mkdir -p "$OUTPUT"
"$REPO_ROOT/build/build.sh"
"$REPO_ROOT/build/build-iso.sh" "$ISO"
"$REPO_ROOT/tests/iso-boot-test.sh" "$ISO"
cp "$REPO_ROOT/build/jane-state.img" "$OUTPUT/jane-state.img"
cat > "$OUTPUT/README.txt" <<EOF
Jane AI OS $VERSION

Boot jane-ai-os-$VERSION.iso as the VM CD/DVD.
Attach jane-state.img as a second virtio disk for persistent memory, identity, and audit state.

The ISO is immutable. The state image is private VM data and should be backed up separately.
EOF
(cd "$OUTPUT" && sha256sum "jane-ai-os-$VERSION.iso" jane-state.img README.txt > SHA256SUMS)
echo "Release bundle ready: $OUTPUT"