# Robert's Raspberry Pi Stuff

This is my personal collection of stuff for use with the pi. Gradually checking things in.

## Ansible playbooks and roles

### Roles

#### pi-basic

This role sets up basic stuff. Sets the password, ssh key, keyboard layout, hostname,
timezone. It changes the gpu mem split to 16MB and disables audio. /var/log is put onto a
ramdisk, and performs an apt upgrade. The apt upgrade can take some time, so optionally
`--skip-tags=aptupgrade` to skip it.

#### pi-rtc

Additional basic role to setup I2C for the RTC. This needs a reboot to update the device
tree settings, so it will force handlers to run mid way through the role for this to
occur.

#### pi-wifi

A very simple role to produce the `wpa_supplicant.conf` file for /boot. This file enables
wifi. The role is written so it can be called separately also. (Playbook
basicwificonfig.yml). There is also the option of creating the enable ssh flag file.

Available flags (with default options as shown) are:

```yaml
piwifi_enabled: true
piwifi_ssh_enable: true
```

#### pi-pihole

A role to download and install Pi-hole. The system should already be on a static IP before
entering this role. The unattended pi-hole install completes the whole setup. Only DNS is
enabled, so no risk to DHCP by running this role.

### Playbooks

* `basicwificonfig.yml` Simple play to generate the file for SD card writer.
* `setup-pihole.yml` Complete play to setup a pi from scratch and turn it into a pihole.

## QEMU

A basic setup and run script is here for running a virtual pi in qemu. The kernel used
doesn't match what's inside the image, so kernel modules won't be able to load. For most
things this is ok and this is a helpful tool for rapid iteration of playbooks.
The `setup.sh` script downloads the kernel and ensures qemu is installed. The base image
is left on disk, enabling easy rollback by running the `qemu-img convert` step again.
The `run.sh` script launches the emulator. Note: this will reboot ok if necessary, but
poweroff doesn't work and results in a halt only.

To SSH into the virtual instance:
`ssh -p 5022 pi@localhost -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null`

## Scripts and tools

* `raspios.sdcard-setup.sh` SD card writing script, which injects SSH and WIFI
configuration (if required). Directly unpacks from zip file located in `./images/`. This
uses ansible to template the WIFI setup, and uses settings from the vault.
