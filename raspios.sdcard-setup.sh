#!/bin/bash

if [ $# -eq 0 ] ; then
	echo need to supply a parameter for where the raspberry pi device is
	echo eg /dev/sde
	echo optional second parameter for enabling wifi. 1 is enabled
	exit
fi

IMGSRCZIP=images/2022-04-04-raspios-bullseye-armhf-lite.img.xz
IMGSRCZIP=images/2022-04-04-raspios-bullseye-arm64-lite.img.xz
TGTDEVICE=${1}
WIFI=${2:-0} #1 or 0
WIFI_PLAY=playbooks/basic-sdsetup.yml
WIFI_VAR=pisdsetup_dest

if [ "${TGTDEVICE}" == "/dev/sda" ] ; then
	echo WARNING MAKE EXTRA CAREFUL YOU MEAN TO RUN WITH /dev/sda AS THE PATH
	echo WARNING MAKE EXTRA CAREFUL YOU MEAN TO RUN WITH /dev/sda AS THE PATH
	echo WARNING MAKE EXTRA CAREFUL YOU MEAN TO RUN WITH /dev/sda AS THE PATH
	echo WARNING MAKE EXTRA CAREFUL YOU MEAN TO RUN WITH /dev/sda AS THE PATH
#	exit
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
sudo dd if=/dev/zero of=${TGTDEVICE} bs=512 seek=$(( ${DEVSIZE_SECTORS} - 512 ))
echo -e "\n"

echo Writing image to device now...
#unzip -p ${IMGSRCZIP} "*.img" | dd of=${TGTDEVICE} bs=1M status=progress conv=fsync
7z e -so ${IMGSRCZIP} "*.img" | sudo dd of=${TGTDEVICE} bs=1M status=progress conv=fsync
echo -e "\n"
sync

#TGTPART=$(lsblk -o NAME,TYPE -n -p -l ${TGTDEVICE} | awk 'NR==2{print $1}')
TGTPART=/dev/$(ls -1 /sys/block/${TGTDEVICE#/dev/}/${TGTDEVICE#/dev/}*/partition | awk -F'/' 'NR==1{print $5}')
MNTPOINT=$(mktemp -d)
echo Mounting ${TGTPART} on ${MNTPOINT} to enable ssh...
mkdir -p ${MNTPOINT}
sudo mount ${TGTPART} ${MNTPOINT} -o uid=$(id -u),gid=$(id -g)

if [ "${WIFI}" == "1" ] ; then
	EXTRAVARS="-e pisdsetup_wifi_enable=true"
else
	EXTRAVARS="-e pisdsetup_wifi_enable=false"
fi
# enable ssh and set the userconf file for username pi, password from vault
# and wpa_supplicant.conf file, settings from vault if enabled above
if ! out=$( ansible-playbook -vvv -i '127.0.0.1,' ${WIFI_PLAY} -e ${WIFI_VAR}=${MNTPOINT} ${EXTRAVARS} ) ; then
	echo "Ansible playbook setup error:"
	echo $out
else
	echo "Ansible playbook setup complete"
fi
echo $out >> ansible.output.txt
sudo umount ${MNTPOINT}

echo All done
