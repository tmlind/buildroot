#!/bin/busybox sh
#
# Wrapper script for kexec and kexec-droid4 as we need to use kexec-droid4
# to boot v3.0.8 based kernels if non-standard kexec option "devtree" is set.
#

# Does the dtb use "edfe0dd0" instead of "d00df33d"?
check_legacy_dtb() {
	dtb=""

	for var in "$@"; do
		if echo "${var}" | grep "\-l" > /dev/null ||
			echo "${var}" | grep "\--load" > /dev/null; then
			loading=1
			break
		fi
	done

	if [ "${loading}" != 1 ]; then
		return
	fi

	for var in "$@"; do
		if echo "${var}" | grep "\--dtb=" > /dev/null; then
			dtb=$(echo "${var}" | cut -d'=' -f2)
			break
		fi
	done

	if [ ! -f "${dtb}" ]; then
		echo "Could not find dtb"
		exit 1
	fi

	if hexdump -C ${dtb} | head -n1 | grep "ed fe 0d d0" > /dev/null; then
		echo "Found legacy dtb.."
		legacy=1
		break
	fi
}

# Rewrite args for legacy kexec to use --devtree and --atags and assume
# there is an atags file in the same directory as the dtb
run_legacy_kexec() {
	for var in "$@"; do
		shift
		if echo "${var}" | grep "\--dtb=" > /dev/null; then
			legacy_arg=$(echo "${var}" | sed -e 's/--dtb/--devtree/;')
			atag_path=$(dirname $(echo "${var}" | cut -d'=' -f2))
			atag_path="${atag_path}/atags"
			if [ ! -f ${atag_path} ]; then
				echo "No atags file found at ${atag_path}"
				return 1
			fi
		else
			set -- "$@" "$var"
		fi
	done

	if [ "${atag_path}" != "" ]; then
		set - "${legacy_arg}" "$@"
		set - "--atags=${atag_path}" "$@"
	fi

	echo "Starting legacy kexec with: "$@""
	/usr/sbin/kexec-droid4 "$@"
}

check_legacy_dtb "$@"

if [ "${legacy}" == "1" ]; then
	echo "Using legacy kexec.."
	run_legacy_kexec "$@"
else
	/usr/sbin/kexec-mainline "$@"
fi
