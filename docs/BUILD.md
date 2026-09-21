# Build and test

Run `./build/build.sh`. It checks dependencies, fetches Linux 6.12.66 from the official kernel CDN, builds an x86_64 QEMU-capable `bzImage`, stages BusyBox and Jane, produces a gzip initramfs, and runs component tests.

Run `./build/run-qemu.sh` for interactive serial QEMU. Run `./tests/qemu-boot-test.sh` for an automated bounded serial smoke test. `./build/clean.sh` only removes generated build and rootfs staging data.
