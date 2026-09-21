#!/bin/sh
# PID 1 for the JaneAI-IOS initramfs.
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
export HOME=/root
mkdir -p /proc /sys /dev /tmp /root /var /jane/memory
mount -t proc proc /proc 2>/dev/null || echo '[WARN] unable to mount proc'
mount -t sysfs sysfs /sys 2>/dev/null || echo '[WARN] unable to mount sysfs'
mount -t devtmpfs devtmpfs /dev 2>/dev/null || echo '[WARN] unable to mount devtmpfs'
mount -t tmpfs tmpfs /tmp 2>/dev/null || true
hostname janeai 2>/dev/null || true
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
