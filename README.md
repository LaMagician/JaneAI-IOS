# JaneAI-IOS v0.1

JaneAI-IOS is an experimental AI-native Linux prototype. It boots Linux 6.12.66 in QEMU into a BusyBox initramfs and starts a deterministic Jane terminal daemon.

## Quick start

```sh
./build/build.sh
./build/run-qemu.sh
```

The first build downloads the pinned kernel from kernel.org, with automatic fallback to the GitHub Linux stable mirror when kernel.org is unreachable. Required commands are `gcc`, `make`, `curl`, `xz`, `cpio`, `gzip`, and static `busybox`; kernel build headers require `libelf-dev`. `qemu-system-x86_64` is required for runtime boot testing.

At `jane>` try `help`, `status`, `read /etc/hostname`, `write /tmp/note hello`, `remember color blue`, `recall color`, `audit`, `processes`, and `exit`.

## Architecture

```text
Linux 6.12.66 -> initramfs /init -> Jane terminal
                                   -> understand -> planner -> permission -> tool -> result -> memory
```

Jane uses small POSIX-shell modules. The planner emits `action|target|argument`; the daemon checks that plan against the permission layer before a tool executes. Reads, writes, launches, settings, and networking are policy controlled, with allow/deny/confirmation outcomes and an append-only audit log. When QEMU starts with the provided 9p share, state is persisted in `/jane/state` across boots.

## Layout

- `ai/`: daemon, planner, memory, tools, and policy boundary
- `init/`: PID 1 source
- `build/`: reproducible build, QEMU, and clean scripts
- `kernel/`: ignored downloaded source and generated build tree
- `rootfs/`: ignored generated initramfs staging tree
- `tests/`: component and QEMU smoke tests
- `docs/`: implementation notes

## Limitations and roadmap

The daemon is deterministic and QEMU is serial-only. External network access remains denied by default policy; localhost requests require confirmation. State persistence currently depends on the QEMU 9p state mount provided by `build/run-qemu.sh`. Future work adds richer backend adapters, stronger policy controls, GUI, and voice support. See `docs/` for build, architecture, kernel, and security details.
