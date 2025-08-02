# 

编译工具链依旧是我们的老朋友, [`toolchains.bootlin`](https://toolchains.bootlin.com/)

## 编译 Linux Kernel


```bash
# 源码拉下来
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.16.tar.xz

...

# 编译


```


## 编译 uboot

qemu 如果不用 `-bios` 指定 uboot


```bash
make qemu_arm64_defconfig
```

单独启动 `uboot`

```
# -cpu 给上
qemu-system-aarch64 -machine virt -nographic -cpu cortex-a72 -m 2G -bios u-boot.bin
```

## 制作 initrd / ramdiskfs ?????

`initrd` ????? `ramdiskfs`, 前者是一个镜像文件， 后者通常指 `/dev/ram0` 这玩意

内核文档提供的命令 `find . | cpio --quiet -H newc -o | gzip -9 -n > /boot/imagefile.img`

这里有一种方法是将 `ramdiskfs` 和内核弄一起
```
CONFIG_BLK_DEV_INITRD=y
CONFIG_INITRAMFS_SOURCE=""
```

另外正常的就是告诉引导程序 `initrd` 在哪

uboot要么认 `fit` 格式， 要么任 `uboot` 格式(uImage和uInitrd等u开头的)

```bash
# 这里我使用 booti, initrd 会被验证格式
mkimage -A arm64 -T ramdisk -d ./rootfs.cpio.gz uInitrd
```

如果具有 `initrd` 阶段, 可以通过 `rdinit=<path>` 来指定初始化程序, 否则默认使用 `/init`

示例 `/init`, 注意由于使用到了 `mdev`, 确保你使用 `alpine` 或者具备 `mdev` 的 rootfs
```
#!/bin/sh

echo "Loading, please wait..."

[ -d /dev ] || mkdir -m 0755 /dev
[ -d /root ] || mkdir --mode=0700 /root
[ -d /sys ] || mkdir /sys
[ -d /proc ] || mkdir /proc
[ -d /tmp ] || mkdir /tmp
[ -d /mnt ] || mkdir /mnt

# Mount /proc and /sys:
mount -n proc /proc -t proc
mount -n sysfs /sys -t sysfs

# Note that this only becomes /dev on the real filesystem if udev's scripts
# are used; which they will be, but it's worth pointing out
#mount -t tmpfs -o mode=0755 udev /dev
[ -e /dev/console ] || mknod /dev/console c 5 1
[ -e /dev/null ] || mknod /dev/null c 1 3

# this will scan device update /dev list
mdev -s
# /bin/sh -i
# Do your stuff here.
echo "This script just mounts and boots the rootfs, nothing else!"

# Mount the root filesystem.
[ -d /mnt/root ] || mkdir /mnt/root
mount -o rw /dev/mmcblk0 /mnt/root

# Clean up.
umount /proc
umount /sys
# 可以使用 exec switch_root <rootfs_path> [init_path] 后面那个是指定的 init 程序
exec switch_root /mnt/root
```

然后就是 `rootfs`, 这边安装好 `alpine-base` 和 `openrc` 即可, 这基本就是最小的 `rootfs` 了

```
# connect network
ip link set eth0 up
udhcpc

# option, if no magic, just do it
# sed -i 's#https\？：//dl-cdn.alpinelinux.org/alpine#https：//mirrors.tuna.tsinghua.edu.cn/alpine#g' /etc/apk/repositories

# install packages
apk update
apk add alpine-base openrc
# make sure PATH
export PATH=$PATH:/usr/bin:/usr/sbin
# setup alpine
setup-alpne

# enable openrc
rc-update add devfs sysinit
rc-update add dmesg sysinit
rc-update add mdev sysinit
rc-update add hwdrivers sysinit
rc-update add modloop sysinit

rc-update add modules boot
rc-update add sysctl boot
rc-update add hostname boot
rc-update add bootmisc boot
rc-update add syslog boot

rc-update add mount-ro shutdown
rc-update add killprocs shutdown
rc-update add savecache shutdown

rc-update add firstboot default
```


## fs.img

```
qemu-system-aarch64 -machine virt -nographic -cpu cortex-a72 -m 2G -drive file=fs.img,format=raw,if=none,id=fs -device virtio-blk,drive=fs -bios u-boot.bin

# uboot 使用 virtio, load virtio 0:1
# Image 用 booti
load virtio 0:1 ${kernel_addr_r} Image
load virtio 0:1 ${fdt_addr} qemu.dtb
load virtio 0:1 ${ramdisk_addr_r} uInitrd
booti ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr}
```

