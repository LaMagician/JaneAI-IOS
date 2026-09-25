#!/bin/sh
set -eu
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
ROOTFS="$REPO_ROOT/rootfs"
OUT="$REPO_ROOT/build/janeai-initramfs.cpio.gz"
for command in busybox cpio gzip; do command -v "$command" >/dev/null || { echo "missing required command: $command" >&2; exit 1; }; done
mkdir -p "$ROOTFS" "$REPO_ROOT/build"
for name in bin sbin etc proc sys dev tmp root usr var jane; do rm -rf "$ROOTFS/$name"; done
mkdir -p "$ROOTFS/bin" "$ROOTFS/sbin" "$ROOTFS/etc" "$ROOTFS/proc" "$ROOTFS/sys" "$ROOTFS/dev" "$ROOTFS/tmp" "$ROOTFS/root" "$ROOTFS/usr/bin" "$ROOTFS/var" "$ROOTFS/jane/lib" "$ROOTFS/jane/memory"
mkdir -p "$ROOTFS/jane/config" "$ROOTFS/jane/state"
install -m 0755 "$(command -v busybox)" "$ROOTFS/bin/busybox"
for applet in $("$ROOTFS/bin/busybox" --list); do
  [ "$applet" = busybox ] || ln -sf busybox "$ROOTFS/bin/$applet"
done
printf 'janeai\n' > "$ROOTFS/etc/hostname"
printf 'root::0:0:root:/root:/bin/sh\n' > "$ROOTFS/etc/passwd"
install -m 0755 "$REPO_ROOT/init/init.sh" "$ROOTFS/init"
install -m 0755 "$REPO_ROOT/ai/daemon/jane.sh" "$ROOTFS/jane/jane"
install -m 0644 "$REPO_ROOT/ai/permissions/permissions.sh" "$ROOTFS/jane/lib/permissions.sh"
install -m 0644 "$REPO_ROOT/ai/tools/tools.sh" "$ROOTFS/jane/lib/tools.sh"
install -m 0644 "$REPO_ROOT/ai/memory/memory.sh" "$ROOTFS/jane/lib/memory.sh"
install -m 0644 "$REPO_ROOT/ai/planner/planner.sh" "$ROOTFS/jane/lib/planner.sh"
(cd "$ROOTFS" && find . -print | LC_ALL=C sort | cpio --quiet -o -H newc | gzip -n > "$OUT")
test -x "$ROOTFS/init"; test -x "$ROOTFS/jane/jane"; test -s "$OUT"
echo "Initramfs ready: $OUT"
