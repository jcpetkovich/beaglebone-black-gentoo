#!/usr/bin/env bash

# This script is idempotent, it will build everything from scratch assuming
# you've downloaded the stage3 tarball you want, and the portage-latest
# snapshot. It will get you up and running with a beaglebone black install that
# has the USB0 gadget interface completely setup so you can bridge your
# internet, or ssh into 192.168.7.2, just like the out-of-the-box debian
# install.

echo "[THIS SCRIPT USES ROOT, C-c IF YOU HAVEN'T READ IT]"

sleep 5

if [ ! -d staging ]; then
    mkdir staging
fi

if [ ! -f stage3-armv7a_hardfp-*.tar.bz2 ]; then
    echo "Can't find stage3, download stage3-armv7a_hardfp-*.tar.bz2"
    exit 1
fi

if [ ! -f portage-latest.tar.bz2 ]; then
    echo "Can't find portage, download portage-latest.tar.bz2"
    exit 1
fi

if [ ! -d staging/usr/portage ]; then
    echo "[SETTING UP ROOTFS (need root)]"
    sudo tar xavf stage3-armv7a_hardfp-*.tar.bz2 -C staging
    sudo tar xavf portage-latest.tar.bz2 -C staging/usr/
else
    echo "  [SKIPPING BASIC ROOTFS SETUP]"
fi

TARGET_CHOST=armv7a-hardfloat-linux-gnueabi

echo "[BUILDING UBOOT]"
if [ ! -f u-boot/u-boot.img ]; then

    pushd u-boot > /dev/null
    if [ ! -f .config ]; then
        make mrproper
        make ARCH=arm CROSS_COMPILE=${TARGET_CHOST}- am335x_boneblack_config
    fi
    make ARCH=arm CROSS_COMPILE=${TARGET_CHOST}-
    popd
else
    echo "  [SKIPPING UBOOT]"
fi

UBOOT_TOOLS=$(realpath u-boot/tools)
export PATH="${UBOOT_TOOLS}:${PATH}"

echo "[BUILDING KERNEL]"

if [ ! -f linux/arch/arm/boot/uImage ]; then

    pushd linux > /dev/null
    if [ ! -f .config ]; then
        make mrproper
        make ARCH=arm CROSS_COMPILE=${TARGET_CHOST}- bb.org_defconfig
    fi
    make ARCH=arm CROSS_COMPILE=${TARGET_CHOST}- menuconfig
    make ARCH=arm CROSS_COMPILE=${TARGET_CHOST}- -j5
    make ARCH=arm CROSS_COMPILE=${TARGET_CHOST}- -j5 uImage dtbs LOADADDR=0x82000000
    make ARCH=arm CROSS_COMPILE=${TARGET_CHOST}- -j5 modules

    echo "[INSTALLING KERNEL]"
    make ARCH=arm CROSS_COMPILE=${TARGET_CHOST}- INSTALL_MOD_PATH=../staging modules_install
    popd

    cp linux/arch/arm/boot/uImage staging/boot
    cp linux/arch/arm/boot/zImage staging/boot
    cp linux/arch/arm/boot/dts/am335x-boneblack.dtb staging/boot
    mkdir -p staging/boot/uboot

else
    echo "  [SKIPPING KERNEL]"
fi

echo "[INSTALLING SCRIPTS]"
if [ ! -d staging/opt/scripts ]; then
    echo "[(using git...)]"
    pushd staging/opt/ > /dev/null
    sudo git clone https://github.com/RobertCNelson/boot-scripts.git scripts
    popd
else
    echo "  [SKIPPING SCRIPTS]"
fi

echo "[CONFIGURING PORTAGE (never skips, need root)]"
cat <<EOF | sudo tee staging/var/lib/portage/world > /dev/null
app-misc/screen
app-portage/eix
app-portage/genlop
app-portage/gentoolkit
app-portage/layman
dev-embedded/u-boot-tools
sys-apps/usbutils
www-servers/apache
EOF

cat <<EOF | sudo tee staging/etc/portage/make.conf > /dev/null
# CFLAGS Optimized for numerical computation on the beagle
CFLAGS="-O2 -pipe -march=armv7-a -mtune=cortex-a8 -mfpu=neon -mfloat-abi=hard"
CXXFLAGS="${CFLAGS}"
CHOST="armv7a-hardfloat-linux-gnueabi"

# nss because of apache/nginx
USE="bindist nss"

# Decent Python targets
PYTHON_TARGETS="$PYTHON_TARGETS python3_4"
USE_PYTHON="2.7 3.3"

PORTDIR="/usr/portage"
DISTDIR="${PORTDIR}/distfiles"
PKGDIR="${PORTDIR}/packages"

# DISTCC, ADJUST FOR YOUR OWN NUM CORES
MAKEOPTS="-j10 -l1"
FEATURES="distcc"
EOF

echo "[SETTING UP USB GADGET MAGIC (need root)]"

if ! grep g_ether staging/etc/conf.d/modules > /dev/null 2>&1; then
    echo 'modules="g_ether"' | sudo tee -a staging/etc/conf.d/modules > /dev/null

    cat <<EOF | sudo tee staging/etc/conf.d/net > /dev/null
config_eth0="dhcp"

# Static IP for usb0
config_usb0="192.168.7.2/24"
EOF
    pushd staging/etc/init.d > /dev/null
    sudo ln -s net.lo net.usb0
    sudo ln -s net.lo net.eth0
    popd

    pushd staging/etc/runlevels/default > /dev/null
    sudo ln -s /etc/init.d/net.eth0 net.eth0
    sudo ln -s /etc/init.d/net.usb0 net.usb0
    sudo ln -s /etc/init.d/sshd     sshd
    popd

else
    echo "  [SKIPPING USB GADGET]"
fi
