# JaneAI-IOS v0.1

JaneAI-IOS is an experimental AI-native Linux prototype. It boots Linux 6.12.66 in QEMU into a BusyBox initramfs and starts a deterministic Jane terminal daemon.

## Quick start

```sh
./build/build.sh
./build/run-qemu.sh
```

The first build downloads the pinned kernel from kernel.org. Required commands are `gcc`, `make`, `curl`, `xz`, `cpio`, `gzip`, static `busybox`, and `qemu-system-x86_64`. CMake and Python are not required.

At `jane>` try `help`, `status`, `read /etc/hostname`, `write /tmp/note hello`, `remember color blue`, `recall color`, `processes`, and `exit`.

## Architecture

```text
Linux 6.12.66 -> initramfs /init -> Jane terminal
                                   -> understand -> planner -> permission -> tool -> result -> memory
```

Jane uses small POSIX-shell modules. The planner emits `action|target|argument`; the daemon checks that plan against the permission layer before a tool executes. Reads, writes, launches, settings, and networking are policy controlled.

## Layout

- `ai/`: daemon, planner, memory, tools, and policy boundary
- `init/`: PID 1 source
- `build/`: reproducible build, QEMU, and clean scripts
- `kernel/`: ignored downloaded source and generated build tree
- `rootfs/`: ignored generated initramfs staging tree
- `tests/`: component and QEMU smoke tests
- `docs/`: implementation notes

## Limitations and roadmap

The daemon is deterministic, storage is initramfs-only, networking is denied, and QEMU is serial-only. Future work adds durable storage, confirmations, backend adapters, audit logs, GUI, and voice support. See `docs/` for build, architecture, kernel, and security details.
