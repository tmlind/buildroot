#!/bin/busybox sh
#
# Wrapper script for kexec and kexec-droid4 as we need to use kexec-droid4
# to boot v3.0.8 based kernels if non-standard kexec option "devtree" is set.
#
for var in "$@"; do
	if echo "${var}" | grep devtree; then
		legacy=1
		break
	fi
done

if [ "${legacy}" == "1" ]; then
	/usr/sbin/kexec-droid4 "$@"
else
	/usr/sbin/kexec-mainline "$@"
fi
