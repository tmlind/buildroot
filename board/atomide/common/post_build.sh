#!/bin/bash

CURDIR=$(pwd)

# Remove kernel from initramfs
if cd output/target/; then
	rm -f boot/*
	cd $CURDIR
fi

# Overwrite the kernel and modules if available
if cd output/target/lib/modules/; then
    if [ -f /srv/tftp/modules.tar.gz ] && [ /srv/tftp/zImage-omap2plus ]; then
	echo "Removing stock kernel modules.."
	rm -rf 4.*.*
	echo "Overwriting with custom kernel.."
	tar zxf /srv/tftp/modules.tar.gz

	# Note that crypto ccm.ko is needed for wlan
	echo "Removing all except critical modules.."
	rm -rf 4.*/kernel/drivers/bluetooth
	rm -rf 4.*/kernel/drivers/iio
	rm -rf 4.*/kernel/drivers/hsi
	rm -rf 4.*/kernel/drivers/media
	#rm -rf 4.*/kernel/drivers/usb
	rm -rf 4.*/kernel/drivers/thermal
	rm -rf 4.*/kernel/drivers/video
	rm -rf 4.*/kernel/drivers/net/wireless/marvell
	#rm -rf 4.*/kernel/drivers/net/wireless/ti/wl18xx
	rm -rf 4.*/kernel/drivers/sound
	rm -rf 4.*/kernel/drivers/crypto
	rm -rf 4.*/kernel/net/bluetooth
	rm -rf 4.*/kernel/net/phonet
	rm -rf 4.*/kernel/net/rxrpc
	rm -rf 4.*/kernel/sound

	#rm -f 4.*/kernel/drivers/mfd/cpcap.ko
	rm -f 4.*/kernel/drivers/phy/phy-cpcap-usb.ko

	cd $CURDIR
	cp /srv/tftp/zImage-omap2plus output/images/zImage
	cp /srv/tftp/*.dtb output/images/
    fi
fi

# Fix up the wl12xx nvs file and remove old versions
if cd output/target/lib/firmware/ti-connectivity; then

    echo "Removing older firmware.."
    rm -f wl127x-fw-[234].bin
    rm -f wl127x-fw-4-*.bin
    rm -f wl128x-fw-3.bin
    rm -f wl128x-fw-4-*.bin
    rm -f wl18xx-fw-[23].bin
    rm -f wl128x-fw-plt-3.bin
    #rm -f wl127*
    #rm -f wl18*

    echo "Fixing up wl1271-nvs.bin symlink.."
    #rm -f wl12xx-nvs.bin
    #rm -f wl1271-nvs.bin
    # panda
    #ln -s wl128x-nvs.bin wl1271-nvs.bin
    # igepv5
    #ln -s wl127x-nvs.bin wl1271-nvs.bin

    cd $CURDIR
fi

# Generate ssh server certificate
if [ ! -d output/target/etc/ssh ]; then
    mkdir output/target/etc/ssh
fi

echo "Generating new ssh server rsa certificate.."
rm -f output/target/etc/ssh/ssh_host_rsa_key*
ssh-keygen -f output/target/etc/ssh/ssh_host_rsa_key -N '' -b 4096 -t rsa

echo "Generating new ssh server dsa certificate.."
rm -f output/target/etc/ssh/ssh_host_dsa_key*
ssh-keygen -f output/target/etc/ssh/ssh_host_dsa_key -N '' -b 1024 -t dsa

# Add user account
if grep tmlind output/target/etc/passwd; then
    sed -i '/.*tmlind.*/d' output/target/etc/passwd
fi
if grep tmlind output/target/etc/shadow; then
    sed -i '/.*tmlind.*/d' output/target/etc/shadow
fi
echo "tmlind:x:666:666:Linux User,,,:/home/tmlind:/bin/sh" >> output/target/etc/passwd
echo "tmlind:$1$joufw7E4$XQ4Gk13C4SZ4/Am0OOffE1:17038:0:99999:7:::" >> output/target/etc/shadow
if [ ! -d output/target/home/tmlind/.ssh ]; then
    mkdir -p output/target/home/tmlind/.ssh
fi
cat ~/.ssh/internal_rsa.pub > output/target/home/tmlind/.ssh/authorized_keys

# Copy some tools
cp /home/tmlind/src/rwmem/rwmem output/target/home/tmlind/
cp /srv/nfs3/armhf/root/test-musb output/target/home/tmlind/
