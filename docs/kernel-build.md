# Kernel build

The source version is Linux 6.12.66. The build uses x86_64 defconfig plus explicit initramfs, devtmpfs, virtual filesystem, serial console, and virtio options. Linux Kbuild supplies GNU C language flags, so host GCC 15.2.0 does not trigger the historic C23 `bool` and `false` collision. No kernel source is patched. The image is `kernel/build/arch/x86/boot/bzImage`.
