# beaglebone-black-gentoo

These are scripts and tools for setting up and configuring gentoo on the
beaglebone black.

A quick synopses:

wget <stage3 tarball>
wget <portage-latest>

```
$ git clone https://github.com/jcpetkovich/beaglebone-black-gentoo.git
$ cd beaglebone-black-gentoo
$ wget <stage3-armv7a_hardfp tarball>
$ wget <portage-latest.tar.bz2>
$ ./make.sh
$ ./mkroot.sh
$ ./mksdcard.sh
$ sudo ./mksdcard.sh /dev/sdc u-boot/MLO u-boot/u-boot.img linux/arch/arm/boot/uImage deploy.tar.gz
```

The `make.sh` script is idempotent, and will usually "do the right thing", it
will build everything from scratch assuming you've downloaded the stage3 tarball
you want, and the portage-latest snapshot. It will get you up and running with a
beaglebone black install that has the USB0 gadget interface completely setup so
you can bridge your internet, or ssh into 192.168.7.2, just like the
out-of-the-box debian install.
