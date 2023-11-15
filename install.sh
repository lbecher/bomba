#!/bin/bash

export HOSTNAME="bomba-project"
export STORAGE_DEVICE="/dev/mmcblk0"
export ROOT="${STORAGE_DEVICE}p1"

apt update
apt install -y parted debootstrap e2fsprogs git

parted -s $STORAGE_DEVICE mklabel msdos
parted -s $STORAGE_DEVICE mkpart primary ext4 4MiB 100%
parted -s $STORAGE_DEVICE set 1 boot on

export ROOT_PARTUUID=$( blkid -o value -s PARTUUID )

mkfs.ext4 $ROOT
mkdir /mnt/sd
mount $ROOT /mnt/sd

debootstrap --arch=armhf --foreign bookworm /mnt/sd http://deb.debian.org/debian

cp -v -r modules/* /mnt/sd/lib/modules/
cp -v -r boot/* /mnt/sd/boot/

echo "  APPEND earlyprintk root=PARTUUID=$ROOT_PARTUUID rootwait rootfstype=ext4 init=/sbin/init loglevel=0 fsck.repair=yes video=HDMI-A-1:1280x720" >> /mnt/sd/boot/extlinux/extlinux.conf

cp -v /etc/resolv.conf /mnt/loop/etc/resolv.conf

chroot /mnt/sd -c "/debootstrap/debootstrap --second-stage"

echo "LANG=pt_BR.UTF-8" > /mnt/sd/etc/locale.conf
echo "KEYMAP=br-abnt2" > /mnt/sd/etc/vconsole.conf
echo "en_US.UTF-8 UTF-8" > /mnt/sd/etc/locale.gen
echo "pt_BR.UTF-8 UTF-8" >> /mnt/sd/etc/locale.gen

ln -sf /mnt/sd/usr/share/zoneinfo/America/Sao_Paulo /mnt/sd/etc/localtime

echo "$HOSTNAME" > /mnt/sd/etc/hostname
echo "127.0.0.1 localhost.localdomain localhost" > /mnt/sd/etc/hosts
echo "::1 localhost.localdomain localhost" >> /mnt/sd/etc/hosts
echo "127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" >> /mnt/sd/etc/hosts

echo -e "PARTUUID=$ROOT_PARTUUID\t/\text4\tdefaults\t0\t0" > /mnt/sd/etc/fstab

chroot /mnt/sd -c "/bin/apt install -y bash udev sudo u-boot-tools parted initramfs-tools nano iwd network-manager openssh-server ntpdate iputils-ping wget curl dosfstools ntfs-3g xfsprogs e2fsprogs btrfs-progs tar zip unzip binutils build-essential cargo ffmpeg python3 python3-venv python3-pip git htop lm-sensors firmware-misc-nonfree firmware-atheros firmware-realtek debootstrap"

chroot /mnt/sd -c "/sbin/useradd -m -G sudo user"
chroot /mnt/sd -c "/sbin/passwd user"

chroot /mnt/sd -c "/sbin/chsh -s /bin/bash"
chroot /mnt/sd -c "/sbin/chsh -s /bin/bash user"
