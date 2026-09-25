# Kernel build

The source version is Linux 6.12.66. `build/build-kernel.sh` fetches from kernel.org first and falls back to the GitHub Linux stable mirror tag `v6.12.66` when kernel.org is unreachable.

The build uses x86_64 defconfig plus explicit initramfs, devtmpfs, virtual filesystem, serial console, virtio block, and 9p/virtio-9p support for persistent guest state sharing. `DEBUG_INFO_BTF` is disabled to avoid a hard runtime dependency on `pahole` for this baseline prototype. No kernel source is patched.

The output image is `kernel/build/arch/x86/boot/bzImage`.
