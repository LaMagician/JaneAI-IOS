# Build and test

Run `./build/build.sh`. It checks dependencies, fetches Linux 6.12.66 (kernel.org first, then GitHub stable mirror fallback), builds an x86_64 QEMU-capable `bzImage`, stages BusyBox and Jane, produces a gzip initramfs, runs component tests, and runs the QEMU smoke test when `qemu-system-x86_64` is available.

Host prerequisites: `gcc`, `make`, `curl`, `xz`, `cpio`, `gzip`, static `busybox`, and `libelf-dev` (headers for kernel objtool).

Run `./build/run-qemu.sh` for interactive serial QEMU. It exposes `build/state/` to the guest as a writable 9p share mounted at `/jane/state` for persistent Jane memory/configuration across boots.

Run `./tests/qemu-boot-test.sh` for an automated bounded serial smoke test. `./build/clean.sh` only removes generated build and rootfs staging data.
