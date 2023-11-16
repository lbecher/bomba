#!/bin/bash

export HOSTNAME="bomba-project"
export STORAGE_DEVICE="/dev/mmcblk0"
export ROOT="${STORAGE_DEVICE}p1"

apt update
apt install -y parted debootstrap e2fsprogs git

parted -s $STORAGE_DEVICE mklabel msdos
parted -s $STORAGE_DEVICE mkpart primary ext4 1MiB 100%
systemctl daemon-reload

export ROOT_PARTUUID=$( blkid -o value -s PARTUUID $ROOT )

mkfs.ext4 $ROOT
mkdir -p /mnt/debian
mount $ROOT /mnt/debian

debootstrap --arch=armhf --foreign bookworm /mnt/debian http://deb.debian.org/debian
chroot /mnt/debian /debootstrap/debootstrap --second-stage

cp -v -r modules/* /mnt/debian/lib/modules
cp -v -r boot/* /mnt/debian/boot

echo "  APPEND earlyprintk root=PARTUUID=$ROOT_PARTUUID rootwait rootfstype=ext4 init=/sbin/init loglevel=0 fsck.repair=yes video=HDMI-A-1:1280x720" >> /mnt/debian/boot/extlinux/extlinux.conf

cp -v /etc/resolv.conf /mnt/debian/etc/resolv.conf
cp -v sources.list /mnt/debian/etc/apt/sources.list

echo "LANG=pt_BR.UTF-8" > /mnt/debian/etc/locale.conf
echo "KEYMAP=br-abnt2" > /mnt/debian/etc/vconsole.conf
echo "en_US.UTF-8 UTF-8" > /mnt/debian/etc/locale.gen
echo "pt_BR.UTF-8 UTF-8" >> /mnt/debian/etc/locale.gen

ln -sf /mnt/debian/usr/share/zoneinfo/America/Sao_Paulo /mnt/debian/etc/localtime

echo "$HOSTNAME" > /mnt/debian/etc/hostname
echo "127.0.0.1 localhost.localdomain localhost" > /mnt/debian/etc/hosts
echo "::1 localhost.localdomain localhost" >> /mnt/debian/etc/hosts
echo "127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" >> /mnt/debian/etc/hosts

echo -e "PARTUUID=$ROOT_PARTUUID\t/\text4\tdefaults\t0\t0" > /mnt/debian/etc/fstab

chroot /mnt/debian /bin/apt update
chroot /mnt/debian /bin/apt install -y bash udev sudo u-boot-tools parted initramfs-tools nano iwd network-manager openssh-server ntpdate iputils-ping wget curl dosfstools ntfs-3g xfsprogs e2fsprogs btrfs-progs tar zip unzip binutils build-essential cargo ffmpeg python3 python3-venv python3-pip git htop lm-sensors firmware-misc-nonfree firmware-atheros firmware-realtek debootstrap

chroot /mnt/debian /sbin/useradd -m -G sudo user
chroot /mnt/debian /bin/passwd user

chroot /mnt/debian /bin/chsh -s /bin/bash root
chroot /mnt/debian /bin/chsh -s /bin/bash user
