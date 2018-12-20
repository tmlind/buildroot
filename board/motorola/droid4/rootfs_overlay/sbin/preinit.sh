#!/bin/busybox sh
#
# Pre-init wrapper script for kexecboot to allow pivot_root booting to
# the stock Android distro.
#
# Note that eventually some of these features could be maybe patched into
# kexecboot. It already has support for running as standalone init process.
#
# See also the kexec wrapper script, it currently checks for "stock" kernel
# command line option and if --command-line=stock it kills kexecboot and
# control returns to this script running as PID 1.
#
# To debug, configure utagboot to boot normal /sbin/init instead,
# then run this script manually, and maybe uncomment the uart.ko line
# below
#

stock_kernel="3.0.8-g448a95f"
mapphone="mapphone_CDMA"

# See also /etc/preinit to override
enable_uart=0
start_kexecboot=1

init_system() {
	if [ "$$" == "1" ]; then
		export path=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin
		mount -t proc none /proc
		mount -t sysfs none /sys
		mount -t tmpfs none /dev
		mdev -s
	fi

        kernel_version=$(uname -r)
        hardware=$(grep Hardware /proc/cpuinfo | cut -d' ' -f2)
        stock_kexec_modules="/lib/modules/${stock_kernel}/kernel/"
}

load_modules() {
	if echo ${kernel_version} | grep -q "3.0.8-" &&
		[ "${hardware}" == "${mapphone}" ] &&
		[ "$$" == "1" ]; then

		# At least kexec booting at 300MHz rate can be flakey, force 1.2GHz
		echo 1200000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq

		# Ignore noisy stock kernel kexec..
		echo 3 > /proc/sysrq-trigger

		if [ "${enable_uart}" == "1" ]; then
			insmod ${stock_kexec_modules}/uart.ko
		fi
        fi
}

#
# As we start kexecboot as pid 1, we may never boot to the distro to the
# buildroot init. So let's make sure we set a default root password if empty.
# Note that half of the SoC die ID is used by Android for the USB peripheral
# serial number.
#
set_root_passwd() {
	if ! grep "root::" /etc/shadow > /dev/null; then
		return
	fi

	pass=$(cat /sys/board_properties/soc/die_id | sha256sum | head -c12)
	mount -o rw,remount /
	echo -e "${pass}\n${pass}\n" | passwd
	mount -o ro,remount /
}

#
# The initrd.gz in the boot.img starts at ..00 00 00 00 1f 8b but gnu grep
# can't match the leading zeroes and we find multiple hits with
# grep -oban $'\x1f\x8b' boot.img.. We could split the binary using awk
# but the busybox awk currently seems to only match the first hex
# character. Anyways, the initramfs is unlikely to change on a locked
# device, so let's just use a fixed offset of 0x44c000 (4505600)
#
unpack_initramfs() {
	dd skip=$((4505600/512)) bs=512 if=/dev/mmcblk1p14 of=/mnt/initrd.gz

	if ! gzip -d /mnt/initrd.gz; then
		echo "Could not uncompress initrd.gz"
		return 1
	fi

	if ! (cd /mnt && cpio -idm < initrd); then
		echo "Could not unpack initrd"
		return 1
	fi

	rm -f /mnt/initrd

	return 0
}

# We need busybox copied to the initramfs to umount the
# bootloader rootfs
copy_base_files() {
	if ! mkdir -p /mnt/bin || ! mkdir -p /mnt/lib; then
		echo "Could not mkdir base files"
		return 1
	fi

	if ! cp -a /bin/busybox /mnt/bin/ ||
		! cp -a /lib/ld-musl-armhf.so.1 /mnt/lib/ ||
		! cp -a /lib/libc.so /mnt/lib/; then
		echo "Could not copy busybox"
		return 1
	fi
}

prepare_pivot_root() {
	umount /tmp
	umount /mnt
	mount -t tmpfs none /mnt

	if ! unpack_initramfs; then
		return 1
	fi

	if ! copy_base_files; then
		return 1
	fi

	mount --move /dev /mnt/dev
	mount --move /sys /mnt/sys
	mount --move /proc /mnt/proc

	cd /mnt && pivot_root . data
}

if [ -f /etc/preinit ]; then
	. /etc/preinit
fi

init_system
load_modules
set_root_passwd

if [ "${start_kexecboot}" == 1 ]; then
	/usr/bin/kexecboot
fi

if [ "$$" != "1" ]; then
	exit 0
fi

if [ ! -f /tmp/pivot_root ]; then
	echo "Continue normal init.."
	umount /tmp
	umount /dev
	umount /sys
	umount /proc
	exec /sbin/init
else
	echo "Attempting pivot_root to stock Android distro.."

	# Reset LCD virtual resolution for SafeStrap logo
	echo 768,1366 > /sys/class/graphics/fb0/virtual_size
	dd if=/dev/zero of=/dev/fb0

	prepare_pivot_root
	rmmod board_mapphone_emu_uart
	exec /bin/busybox chroot . /bin/busybox sh -c \
	     '/bin/busybox umount /data; exec /init $*' \
	     < /dev/console > /dev/console 2>&1
fi
