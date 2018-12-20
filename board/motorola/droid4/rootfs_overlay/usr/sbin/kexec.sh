#!/bin/busybox sh
#
# Wrapper script for kexec and kexec-droid4 as we need to use kexec-droid4
# to boot v3.0.8 based kernels if non-standard kexec option "devtree" is set.
# Also supports pivot_root booting together with preinit.sh.
#

stock_kernel="3.0.8-g448a95f"
mapphone="mapphone_CDMA"

romslot=""

# Kill kexecboot if pivot_root to stock Android distro is requested.
# Tag /tmp/pivot_root for /sbin/preinit.sh so it can continue to the
# stock Android distro.
check_pivot_root() {
	for var in "$@"; do
		if echo "${var}" | grep "\--command-line=stock" > /dev/null; then
			echo "Stock Android distro pivot_root requested"
			mount -t tmpfs none /tmp
			touch /tmp/pivot_root
			killall kexecboot
			exit 0
		fi
	done
}

# We don't want uart and kexec modules loaded for pivot_root for PM.
# Only load them when needed for kexec.
load_modules() {
	kernel_version=$(uname -r)
	hardware=$(grep Hardware /proc/cpuinfo | cut -d' ' -f2)
	stock_kexec_modules="/lib/modules/${stock_kernel}/kernel/"

	if echo ${kernel_version} | grep -q "3.0.8-" &&
		[ "${hardware}" == "${mapphone}" ]; then

		# At least kexec booting at 300MHz rate can be flakey, force 1.2GHz
		echo 1200000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq

		# Ignore noisy stock kernel kexec..
		echo 3 > /proc/sysrq-trigger

		insmod ${stock_kexec_modules}/uart.ko
		insmod ${stock_kexec_modules}/arm_kexec.ko
		insmod ${stock_kexec_modules}/kexec.ko
        fi
}

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

parse_safestrap_romslot() {
        for var in "$@"; do
                if echo "${var}" | grep "androidboot.safestrap.romslot="; then
			romslot=$(echo "${var}" | awk -F'=' '{print $(NF-0)}')
			romslot=$(echo "${romslot}" | sed -e 's/"//')
			echo "Selected romslot is ${romslot}.."
                fi
        done
}

fixup_safestrap_romslot() {
	if [ "${romslot}" == "" ]; then
		return
	fi
	mount -o rw /dev/mmcblk1p25 /mnt
	if [ -f /mnt/safestrap/active_slot ]; then
		current_slot=$(cat /mnt/safestrap/active_slot)
		if [ "${current_slot}" != "${romslot}" ]; then
			echo -n "Updating SafeStrap romslot "
			echo ""${current_slot}" to "${romslot}""
			echo "${romslot}" > /mnt/safestrap/active_slot
		fi
	fi
	umount /mnt
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

check_pivot_root "$@"
load_modules
check_legacy_dtb "$@"

if [ "${legacy}" == "1" ]; then
	echo "Using legacy kexec.."
	parse_safestrap_romslot "$@"
	fixup_safestrap_romslot
	run_legacy_kexec "$@"
else
	/usr/sbin/kexec-mainline "$@"
fi
