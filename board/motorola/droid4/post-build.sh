#!/bin/sh

if [ "${TARGET_DIR}" = "" ]; then
	echo "No TARGET_DIR in environment"
	exit 1
fi

# Create an empty /lib/firmware mount point for tmpfs. We can save
# space by copying the stock kernel firmware to tmpfs for WLAN on boot.
#
if [ ! -d ${TARGET_DIR}/lib/firmware ]; then
	mkdir -p ${TARGET_DIR}/lib/firmware
fi

#
# Only enable networking if user creates /etc/wpa_supplicant.conf.
#
rm -f ${TARGET_DIR}/etc/wpa_supplicant.conf

#
# Droid 4 stock kernel needs absolute paths for busybox links, probably
# due to selinux. We cannot use BR2_PACKAGE_BUSYBOX_INDIVIDUAL_BINARIES
# as it bloats up the rootfs past the 4MB size we have available in
# mmcblk1p13.
#
rewrite_link() {
	old_link=$1
	new_link=$2

	if [ -L ${old_link} ]; then
		echo "could not find ${old_link}"
		exit 1
	fi

	if ! rm -f ${old_link}; then
		echo "could not remove ${old_link}"
		exit 1
	fi

	if ! ln -s ${new_link} ${old_link}; then
		echo "could not add a symlink for ${new_link}"
		exit 1
	fi
}

rewrite_links() {
	old_links=$1
	new_link=$2

	for link in ${old_links}; do
		rewrite_link "${link}" "${new_link}"
	done
}

sbin_links=$(find ${TARGET_DIR}/sbin -lname ../bin/busybox)
usr_bin_links=$(find ${TARGET_DIR}/usr/bin -lname ../../bin/busybox)
usr_sbin_links=$(find ${TARGET_DIR}/usr/sbin -lname ../../bin/busybox)

if [ "${sbin_links}" != "" ]; then
	rewrite_links "${sbin_links}" "/bin/busybox"
fi
if [ "${usr_bin_links}" != "" ]; then
	rewrite_links "${usr_bin_links}" "/bin/busybox"
fi
if [ "${usr_sbin_links}" != "" ]; then
	rewrite_links "${usr_sbin_links}" "/bin/busybox"
fi

#
# Configure kexec wrapper script for v3.0.8 kernels
#
if [ -f ${TARGET_DIR}/usr/sbin/kexec ] &&
		[ -f ${TARGET_DIR}/usr/sbin/kexec-droid4 ]; then
	mv ${TARGET_DIR}/usr/sbin/kexec ${TARGET_DIR}/usr/sbin/kexec-mainline
	mv ${TARGET_DIR}/usr/sbin/kexec.sh ${TARGET_DIR}/usr/sbin/kexec
fi
