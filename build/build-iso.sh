#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
KERNEL="$REPO_ROOT/kernel/build/arch/x86/boot/bzImage"
INITRAMFS="$REPO_ROOT/build/janeai-initramfs.cpio.gz"
DESKTOP=${XDG_DESKTOP_DIR:-"$HOME/Desktop"}
OUTPUT=${1:-"$DESKTOP/jane-ai-os-v0.1.iso"}

for command in grub-mkrescue xorriso; do
  command -v "$command" >/dev/null || {
    echo "missing required dependency: $command" >&2
    exit 1
  }
done
test -s "$KERNEL" && test -s "$INITRAMFS" || {
  echo 'Build first: ./build/build.sh' >&2
  exit 1
}

WORK=$(mktemp -d "${TMPDIR:-/tmp}/jane-ai-os-iso.XXXXXX")
trap 'rm -rf "$WORK"' EXIT HUP INT TERM
mkdir -p "$WORK/boot/grub" "$(dirname -- "$OUTPUT")"
cp "$KERNEL" "$WORK/boot/bzImage"
cp "$INITRAMFS" "$WORK/boot/janeai-initramfs.cpio.gz"
cat > "$WORK/boot/grub/grub.cfg" <<'EOF'
set timeout=3
set default=0

menuentry 'Jane AI OS v0.1' {
    linux /boot/bzImage console=tty0 console=ttyS0 rdinit=/init
    initrd /boot/janeai-initramfs.cpio.gz
}
EOF

grub-mkrescue --output="$OUTPUT" "$WORK" >/dev/null
test -s "$OUTPUT"
echo "ISO ready: $OUTPUT"