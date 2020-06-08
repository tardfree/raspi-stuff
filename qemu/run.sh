#!/bin/bash

#Assumes setup already run
TARGETDIR=runtime
KERNEL=( ${TARGETDIR}/kernel-qemu-* )
DTB=( ${TARGETDIR}/versatile-pb*dtb )
IMG=( ${TARGETDIR}/*buster*qcow2 )
echo Starting qemu with ${KERNEL} and ${DTB}

#other param options found here: https://github.com/lukechilds/dockerpi/blob/master/entrypoint.sh
qemu-system-arm \
  --machine versatilepb \
  --cpu arm1176 \
  --m 256 \
  --drive format=qcow2,file=${IMG} \
  --net nic \
  --net user,hostfwd=tcp::5022-:22 \
  --dtb ${DTB} \
  --kernel ${KERNEL} \
  --append 'root=/dev/sda2 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait' # panic=1'

#  --no-reboot
# this means any reboot will quit the emulator
# panic=1 on command line means halt will trigger a reboot
# without panic=1 halt triggers a halt but no power off
