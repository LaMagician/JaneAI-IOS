#!/bin/sh
set -eu
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
VERSION=6.12.66
SOURCE="$REPO_ROOT/kernel/linux-6.12"
OUTPUT="$REPO_ROOT/kernel/build"
TARBALL="$REPO_ROOT/kernel/linux-$VERSION.tar.xz"
URL="https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$VERSION.tar.xz"
command -v gcc >/dev/null; command -v make >/dev/null; command -v curl >/dev/null; command -v xz >/dev/null
if [ ! -f "$SOURCE/Makefile" ]; then
  if ! xz -t "$TARBALL" 2>/dev/null; then
    echo "Downloading Linux $VERSION from kernel.org"
    curl --fail --location --retry 3 --continue-at - --output "$TARBALL" "$URL"
  fi
  rm -rf "$SOURCE"
  tar -C "$REPO_ROOT/kernel" -xf "$TARBALL"
  mv "$REPO_ROOT/kernel/linux-$VERSION" "$SOURCE"
fi
mkdir -p "$OUTPUT"
make -C "$SOURCE" O="$OUTPUT" ARCH=x86_64 defconfig
"$SOURCE/scripts/config" --file "$OUTPUT/.config" --enable BLK_DEV_INITRD --enable DEVTMPFS --enable DEVTMPFS_MOUNT --enable PROC_FS --enable SYSFS --enable TMPFS --enable EXT4_FS --enable SERIAL_8250 --enable SERIAL_8250_CONSOLE --enable SERIAL_8250_PCI --enable VIRTIO --enable VIRTIO_PCI --enable VIRTIO_BLK --enable 9P_FS
make -C "$SOURCE" O="$OUTPUT" ARCH=x86_64 olddefconfig
make -C "$SOURCE" O="$OUTPUT" ARCH=x86_64 -j"$(nproc)" bzImage
test -s "$OUTPUT/arch/x86/boot/bzImage"
echo "Kernel ready: $OUTPUT/arch/x86/boot/bzImage"
