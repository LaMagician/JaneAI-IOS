#!/bin/sh
# PID 1 for the JaneAI-IOS initramfs.
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
export HOME=/root
mkdir -p /proc /sys /dev /tmp /root /var /jane/memory /jane/state
mount -t proc proc /proc 2>/dev/null || echo '[WARN] unable to mount proc'
mount -t sysfs sysfs /sys 2>/dev/null || echo '[WARN] unable to mount sysfs'
mount -t devtmpfs devtmpfs /dev 2>/dev/null || echo '[WARN] unable to mount devtmpfs'
mount -t tmpfs tmpfs /tmp 2>/dev/null || true
if mount -t ext4 /dev/vda /jane/state 2>/dev/null; then
    mkdir -p /jane/state/memory /jane/state/audit /jane/state/identity
    export JANE_MEMORY_FILE=/jane/state/memory/facts.tsv
    export JANE_AUDIT_FILE=/jane/state/audit/events.log
    export JANE_IDENTITY_DIR=/jane/state/identity
    echo '[OK] Persistent state mounted'
else
    echo '[WARN] Persistent state disk unavailable; using ephemeral state'
fi
hostname janeai 2>/dev/null || true
printf '\n=====================================\n'
printf '         JANEAI-IOS v0.1\n'
printf '       AI-NATIVE OPERATING SYSTEM\n'
printf '=====================================\n'
echo '[OK] Kernel initialized'
echo '[OK] Filesystems initialized'
if [ -x /jane/jane ]; then
    echo '[OK] Jane userspace initialized'
    attempts=0
    while [ "$attempts" -lt 3 ]; do
        echo '[OK] AI daemon starting'
        /jane/jane
        status=$?
        attempts=$((attempts + 1))
        echo "[WARN] Jane daemon stopped (status=$status, restart=$attempts/3)"
        [ "$attempts" -lt 3 ] && continue
    done
    if [ "${JANE_RECOVERY:-0}" = 1 ]; then
        echo '[WARN] Explicit recovery mode enabled; opening shell'
        exec sh
    fi
    echo '[ERROR] Jane daemon failed repeatedly; system is staying in recovery wait mode'
    while :; do sleep 60; done
fi
if [ "${JANE_RECOVERY:-0}" = 1 ]; then
    echo '[WARN] Explicit recovery mode enabled; opening shell'
    exec sh
fi
echo '[ERROR] Jane daemon unavailable; system is staying in recovery wait mode'
while :; do sleep 60; done
