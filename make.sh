#!/usr/bin/env bash

if [[ ! -d staging/usr/portage ]]; then
    tar xavf stage3-armv7a_hardfp-20150508.tar.bz2 -C staging
    tar xavf portage-latest.tar.bz2 -C staging/usr/
fi

pushd u-boot > /dev/null
make mrproper
make ARCH=arm CROSS_COMPILE=armv7a-hardfloat-linux-gnueabihf- am335x_boneblack_config
make ARCH=arm CROSS_COMPILE=armv7a-hardfloat-linux-gnueabihf-
popd

pushd linux > /dev/null
make mrproper
make ARCH=arm CROSS_COMPILE=armv7a-hardfloat-linux-gnueabihf- bb.org_defconfig
make ARCH=arm CROSS_COMPILE=armv7a-hardfloat-linux-gnueabihf- menuconfig
make ARCH=arm CROSS_COMPILE=armv7a-hardfloat-linux-gnueabihf- -j5
make ARCH=arm CROSS_COMPILE=armv7a-hardfloat-linux-gnueabihf- -j5 uImage dtbs LOADADDR=0x82000000
make ARCH=arm CROSS_COMPILE=armv7a-hardfloat-linux-gnueabihf- -j5 modules
make ARCH=arm CROSS_COMPILE=armv7a-hardfloat-linux-gnueabihf- INSTALL_MOD_PATH=../staging modules_install
popd

cp linux/arch/arm/boot/zImage staging/boot
cp linux/arch/arm/boot/dts/am335x-boneblack.dtb staging/boot
mkdir -p staging/boot/uboot
