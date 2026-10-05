# Build and test

Run `./build/build.sh`. It checks dependencies, fetches Linux 6.12.66 from the official kernel CDN, builds an x86_64 QEMU-capable `bzImage`, stages BusyBox and Jane, produces a gzip initramfs, and runs component tests.

Run `./build/run-qemu.sh` for interactive serial QEMU. Run `./tests/qemu-boot-test.sh` for an automated bounded serial smoke test. `./build/clean.sh` only removes generated build and rootfs staging data.

Run `./tests/resource-test.sh` to measure the low-end profile. It boots the 256 MiB development guest, verifies Jane becomes ready, and checks peak host RSS remains below 512 MiB.

The normal QEMU launcher creates `build/jane-state.img`, a 64 MiB ext4 disk attached as virtio and mounted at `/jane/state`. Audit logs, identity onboarding, and memory facts use that disk. The image is preserved across QEMU boots; remove it explicitly when a clean identity is required.

Run `./build/build-iso.sh` to create a BIOS/UEFI bootable ISO at `~/Desktop/jane-ai-os-v0.1.iso`. Pass a path to write elsewhere, for example `./build/build-iso.sh /tmp/jane-ai-os.iso`. The ISO embeds the built kernel and initramfs and uses the same `/init` boot path as the QEMU kernel launch. For persistent state in a VM booted from the ISO, attach `build/jane-state.img` as a second virtio disk.

Run `./build/build-release.sh` to produce a deployable Desktop bundle containing the ISO, persistent state disk, usage instructions, and `SHA256SUMS`. The bundle runs the low-end resource test and direct ISO boot test before reporting success.
