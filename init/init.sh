#!/bin/sh
# PID 1 for the JaneAI-IOS initramfs.
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
export HOME=/root
mkdir -p /proc /sys /dev /tmp /root /var /jane /jane/memory /jane/config /jane/state
mount -t proc proc /proc 2>/dev/null || echo '[WARN] unable to mount proc'
mount -t sysfs sysfs /sys 2>/dev/null || echo '[WARN] unable to mount sysfs'
mount -t devtmpfs devtmpfs /dev 2>/dev/null || echo '[WARN] unable to mount devtmpfs'
mount -t tmpfs tmpfs /tmp 2>/dev/null || true
if mount -t 9p -o trans=virtio,version=9p2000.L janestate /jane/state 2>/dev/null; then
    mkdir -p /jane/state/memory /jane/state/config
    export JANE_STATE_DIR=/jane/state
    echo '[OK] Persistent Jane state mounted'
else
    export JANE_STATE_DIR=/jane
    echo '[WARN] Persistent Jane state unavailable; using volatile state'
fi
JANE_SETTINGS_FILE="$JANE_STATE_DIR/config/settings.conf"
if [ -f "$JANE_SETTINGS_FILE" ]; then
    host_setting=$(awk -F= '$1 == "hostname" { print $2 }' "$JANE_SETTINGS_FILE" | tail -n1)
    [ -n "$host_setting" ] && hostname "$host_setting" 2>/dev/null || true
else
    hostname janeai 2>/dev/null || true
fi
printf '\n=====================================\n'
printf '         JANEAI-IOS v0.1\n'
printf '       AI-NATIVE OPERATING SYSTEM\n'
printf '=====================================\n'
echo '[OK] Kernel initialized'
echo '[OK] Filesystems initialized'
if [ -x /jane/jane ]; then
    echo '[OK] Jane userspace initialized'
    echo '[OK] AI daemon started'
    exec /jane/jane
fi
echo '[ERROR] Jane daemon unavailable; opening recovery shell'
exec sh
