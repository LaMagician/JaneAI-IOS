#!/bin/sh
set -eu
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
VERSION=6.12.66
SOURCE="$REPO_ROOT/kernel/linux-6.12"
OUTPUT="$REPO_ROOT/kernel/build"
TARBALL_XZ="$REPO_ROOT/kernel/linux-$VERSION.tar.xz"
TARBALL_GZ="$REPO_ROOT/kernel/linux-$VERSION.tar.gz"
KERNEL_ORG_URL="https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$VERSION.tar.xz"
GITHUB_STABLE_URL="https://codeload.github.com/gregkh/linux/tar.gz/refs/tags/v$VERSION"
command -v gcc >/dev/null; command -v make >/dev/null; command -v curl >/dev/null; command -v xz >/dev/null; command -v tar >/dev/null
mkdir -p "$REPO_ROOT/kernel"
download_kernel_source() {
  if curl --fail --location --retry 3 --continue-at - --output "$TARBALL_XZ" "$KERNEL_ORG_URL"; then
    echo "Downloaded Linux $VERSION from kernel.org"
    return 0
  fi
  rm -f "$TARBALL_XZ"
  curl --fail --location --retry 3 --continue-at - --output "$TARBALL_GZ" "$GITHUB_STABLE_URL"
  echo "Downloaded Linux $VERSION from GitHub stable mirror"
}
extract_kernel_source() {
  archive=$1
  [ -f "$archive" ] || return 1
  rm -rf "$SOURCE"
  tar -C "$REPO_ROOT/kernel" -xf "$archive"
  if [ -d "$REPO_ROOT/kernel/linux-$VERSION" ]; then
    mv "$REPO_ROOT/kernel/linux-$VERSION" "$SOURCE"
    return 0
  fi
  if [ -d "$REPO_ROOT/kernel/linux-$VERSION-stable" ]; then
    mv "$REPO_ROOT/kernel/linux-$VERSION-stable" "$SOURCE"
    return 0
  fi
  extracted_dir=$(tar -tf "$archive" | head -n1 | cut -d/ -f1)
  [ -n "$extracted_dir" ] && [ -d "$REPO_ROOT/kernel/$extracted_dir" ] || return 1
  mv "$REPO_ROOT/kernel/$extracted_dir" "$SOURCE"
}
if [ ! -f "$SOURCE/Makefile" ]; then
  if ! xz -t "$TARBALL_XZ" 2>/dev/null && ! tar -tzf "$TARBALL_GZ" >/dev/null 2>&1; then
    download_kernel_source
  fi
  extract_kernel_source "$TARBALL_XZ" || extract_kernel_source "$TARBALL_GZ"
fi
mkdir -p "$OUTPUT"
make -C "$SOURCE" O="$OUTPUT" ARCH=x86_64 defconfig
"$SOURCE/scripts/config" --file "$OUTPUT/.config" --enable BLK_DEV_INITRD --enable DEVTMPFS --enable DEVTMPFS_MOUNT --enable PROC_FS --enable SYSFS --enable TMPFS --enable EXT4_FS --enable SERIAL_8250 --enable SERIAL_8250_CONSOLE --enable SERIAL_8250_PCI --enable VIRTIO --enable VIRTIO_PCI --enable VIRTIO_BLK --enable 9P_FS --enable NET_9P --enable NET_9P_VIRTIO --disable DEBUG_INFO_BTF
make -C "$SOURCE" O="$OUTPUT" ARCH=x86_64 olddefconfig
make -C "$SOURCE" O="$OUTPUT" ARCH=x86_64 -j"$(nproc)" bzImage
test -s "$OUTPUT/arch/x86/boot/bzImage"
echo "Kernel ready: $OUTPUT/arch/x86/boot/bzImage"
