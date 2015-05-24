#!/usr/bin/env bash

if [ ! -f stage3-armv7a_hardfp-*.tar.bz2 ]; then
    echo "Download stage3-armv7a_hardfp-*.tar.bz2"
    exit 1
fi

if [[ ! -f portage-latest.tar.bz2 ]]; then
    echo "and portage-latest.tar.bz2"
    exit 1
fi

echo "[SETTING UP STAGING]"
if [[ ! -d staging/usr/portage ]]; then
    tar xavf stage3-armv7a_hardfp-*.tar.bz2 -C staging
    tar xavf portage-latest.tar.bz2 -C staging/usr/
fi

TARGET_CHOST=armv7a-hardfloat-linux-gnueabi

echo "[BUILDING UBOOT]"
pushd u-boot > /dev/null
make mrproper
make ARCH=arm CROSS_COMPILE=${TARGET_CHOST}- am335x_boneblack_config
make ARCH=arm CROSS_COMPILE=${TARGET_CHOST}-
popd

UBOOT_TOOLS=$(realpath u-boot/tools)
export PATH="${UBOOT_TOOLS}:${PATH}"

echo "[BUILDING KERNEL]"
pushd linux > /dev/null
make mrproper
make ARCH=arm CROSS_COMPILE=${TARGET_CHOST}- bb.org_defconfig
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

echo "[CONFIGURING PORTAGE]"
cat <<EOF > staging/var/lib/portage/world
app-misc/screen
app-portage/eix
app-portage/genlop
app-portage/gentoolkit
app-portage/layman
sys-apps/usbutils
www-servers/apache
EOF
