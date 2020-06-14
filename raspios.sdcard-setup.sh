#!/bin/bash

if [ $# -eq 0 ] ; then
	echo need to supply a parameter for where the raspberry pi device is
	echo eg /dev/sde
	echo optional second parameter for enabling wifi. 1 is enabled
	exit
fi

IMGSRCZIP=images/2020-05-27-raspios-buster-lite-armhf.zip
TGTDEVICE=${1}
WIFI=${2:-0} #1 or 0
WIFI_PLAY=playbooks/basicwificonfig.yml
WIFI_VAR=piwifi_dest

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
echo "ssh" > ${MNTPOINT}/ssh
if [ "${WIFI}" == "1" ] ; then
	#wpa_supplicant.conf file produced via ansible template module. settings from vault.
	if ! out=$( ansible-playbook -i '127.0.0.1,' ${WIFI_PLAY} -e ${WIFI_VAR}=${MNTPOINT} -e ansible_python_interpreter=/usr/bin/python3 ) ; then
		echo "Wifi setup error:"
		echo $out
	else
		echo "Wifi setup complete"
	fi
fi
sudo umount ${MNTPOINT}

echo All done
