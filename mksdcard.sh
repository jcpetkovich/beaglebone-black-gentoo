#!/usr/bin/env bash
if [[ -z $1 || -z $2 || -z $3 || -z $4 ]]
then
    echo "mksd-am335x Usage:"
    echo "	mksd-am335x <device> <MLO> <u-boot.img> <uImage> <rootfs tar.gz >"
    echo "	Example: mksd-am335x /dev/sdc MLO u-boot.img uImage nfs.tar.gz"
    exit
fi
if ! [[ -e $2 ]]
then
    echo "Incorrect MLO location!"
    exit
fi
if ! [[ -e $3 ]]
then
    echo "Incorrect u-boot.img location!"
    exit
fi
if ! [[ -e $4 ]]
then
    echo "Incorrect uImage location!"
    exit
fi
if ! [[ -e $5 ]]
then
    echo "Incorrect rootfs location!"
    exit
fi

echo "All data on "$1" now will be destroyed! Continue? [y/n]"
read ans
if ! [ $ans == 'y' ]
then
    exit
fi

echo "[Partitioning $1...]"

DRIVE=$1
dd if=/dev/zero of=$DRIVE bs=1024 count=1024

SIZE=`fdisk -l $DRIVE | grep Disk | awk '{print $5}'`

echo DISK SIZE - $SIZE bytes

CYLINDERS=`echo $SIZE/255/63/512 | bc`

echo CYLINDERS - $CYLINDERS
{
    echo ,9,0x0C,*
    echo ,,,-
} | sfdisk -D -H 255 -S 63 -C $CYLINDERS $DRIVE

echo "[Making filesystems...]"

mkfs.vfat -F 32 -n boot "$1"1 &> /dev/null
# the "-T small" is so I have enough inodes for portage
mkfs.ext4 -L rootfs -T small "$1"2 &> /dev/null

echo "[Copying files...]"

mount "$1"1 /mnt/sdcard
cp $2 /mnt/sdcard/MLO
cp $3 /mnt/sdcard/u-boot.img
umount "$1"1

mount "$1"2 /mnt/sdcard
tar zxvf $5 -C /mnt/sdcard
chmod 755 /mnt/sdcard
umount "$1"2

echo "[Done]"
