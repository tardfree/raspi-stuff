#!/bin/bash

RASPIOS_ZIP=../images/2021-05-07-raspios-buster-armhf-lite.zip
#https://github.com/dhruvvyas90/qemu-rpi-kernel
QEMUKERNEL=https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/kernel-qemu-5.4.51-buster
DTBFILE=https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/versatile-pb-buster-5.4.51.dtb
MNTPOINT=/mnt/1
TARGETDIR=runtime

echo Get the things
mkdir -p ${TARGETDIR}
wget -nc --quiet --show-progress -P ${TARGETDIR} ${QEMUKERNEL}
wget -nc --quiet --show-progress -P ${TARGETDIR} ${DTBFILE}
unzip ${RASPIOS_ZIP} -d ${TARGETDIR}

echo Install qemu
sudo dnf install -y qemu-system-arm

echo Resizing disk
IMG=( ${TARGETDIR}/*buster*img )
truncate -s 4G ${IMG}
parted ${IMG} resizepart 2 100%
#note: ext4 gets grown on boot by the raspios

echo Enable ssh
mkdir -p ${MNTPOINT}
F32SECTORSTART=$(fdisk -l ${IMG} | grep FAT32 | awk '{print $2}')
sudo mount -o rw,loop,offset=$((${F32SECTORSTART}*512)) ${IMG} ${MNTPOINT}
sudo touch ${MNTPOINT}/ssh
sudo umount ${MNTPOINT}

echo Converting image
echo qemu-img convert -f raw ${IMG} -O qcow2 ${IMG%.*}.qcow2
qemu-img convert -f raw ${IMG} -O qcow2 ${IMG%.*}.qcow2
rm -f ${IMG}

echo Done
