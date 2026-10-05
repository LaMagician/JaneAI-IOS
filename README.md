# JaneAI-IOS v0.1

JaneAI-IOS is an experimental AI-native Linux prototype. It boots Linux 6.12.66 in QEMU into a BusyBox initramfs and starts a deterministic Jane terminal daemon.

## Quick start

```sh
./build/build.sh
./build/run-qemu.sh
python3 tools/jane-interface.py
```

`./build/run-qemu.sh` preserves Jane's audit log, identity, and memory in `build/jane-state.img`. Keep that disk with the VM; the ISO itself is immutable and remains stateless when booted without a second disk.

The first build downloads the pinned kernel from kernel.org. Required commands are `gcc`, `make`, `curl`, `xz`, `cpio`, `gzip`, static `busybox`, `qemu-system-x86_64`, `python3`, `espeak-ng`, and `pocketsphinx_continuous`. CMake is not required.

The native host interface provides a chat window over QEMU serial, typed requests, offline speech recognition through PocketSphinx, and spoken replies through `espeak-ng`. The `Listen` button records a 16 kHz mono WAV file and sends it to PocketSphinx by default. A better recognizer can override this with `JANE_STT_COMMAND`; the command receives a WAV file path and must print one transcript line.

At `jane>` try `help`, `status`, `hardware`, `read /etc/hostname`, `write /tmp/note hello`, `remember color blue`, `recall color`, `find color`, `context`, `processes`, and `exit`.

Hardware profiles are selected at startup. Advanced users can override them with `JANE_RESOURCE_PROFILE_OVERRIDE`, `JANE_MODEL_PROFILE_OVERRIDE`, `JANE_CONTEXT_TOKENS_OVERRIDE`, and `JANE_VOICE_MODE_OVERRIDE`. A CPU-friendly local runtime can be configured with `JANE_MODEL_RUNTIME` and `JANE_MODEL_FILE`; the adapter passes the selected thread count, context limit, and generation limit to a llama.cpp-compatible CLI. Without those variables Jane remains deterministic and offline.

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
