#!/bin/bash

if [ $# -eq 0 ] ; then
	echo need to supply a parameter for where the raspberry pi device is
	echo eg /dev/sde
	exit
fi

IMGSRCZIP=images/2020-05-27-raspios-buster-lite-armhf.zip
TGTDEVICE=${1}
MNTPOINT=/mnt/2

if [ "${TGTDEVICE}" == "/dev/sda" ] ; then
	echo refusing to run with /dev/sda as the path
	exit
fi 

if [ ! -f "${IMGSRCZIP}" ] ; then
	echo IMGSRCZIP ${IMGSRCZIP} does not exist
	exit
fi

echo Setting up an SD card for raspberry pi onto ${TGTDEVICE}
read -p "Press [Enter] key to start... (or ctrl-c to abort)"
echo -e "\n"

#write 0's to start and end of sd card
SHORTDEVNAME=${TGTDEVICE/\/dev\//}
DEVSIZE_SECTORS=$(cat /sys/block/${SHORTDEVNAME}/size)
echo Writing zeros to the end of the device...
dd if=/dev/zero of=${TGTDEVICE} bs=512 seek=$(( ${DEVSIZE_SECTORS} - 512 ))
echo -e "\n"

echo Writing image to device now...
#unzip -p ${IMGSRCZIP} "*.img" | dd of=${TGTDEVICE} bs=1M status=progress conv=fsync
7z e -so ${IMGSRCZIP} "*.img" | dd of=${TGTDEVICE} bs=1M status=progress conv=fsync
echo -e "\n"
sync

#TGTPART=$(lsblk -o NAME,TYPE -n -p -l ${TGTDEVICE} | awk 'NR==2{print $1}')
TGTPART=/dev/$(ls -1 /sys/block/${TGTDEVICE#/dev/}/${TGTDEVICE#/dev/}*/partition | awk -F'/' 'NR==1{print $5}')
echo Mounting ${TGTPART} on ${MNTPOINT} to enable ssh...
mkdir -p ${MNTPOINT}
mount ${TGTPART} ${MNTPOINT}
echo "blah" > ${MNTPOINT}/ssh
echo "blah" > ${MNTPOINT}/ssh.txt
umount ${MNTPOINT}

echo All done
