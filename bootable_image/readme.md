## Bootable disk script

This script automates the process of creating a disk (.img) file with two partitions, a filesytem and a bootable partition.

### How to use

`./make_img.sh <filename>` 

In the future will add args to provide paths and configuration. For now you have to hardcode this.

### Exit codes

(1) Wrong number of args || `dd` command failed to create .img
(2) Partition table failed `mklabel`
(3) Partition creation failed `mkpart`
(4) Make bootable partition 1 failed `set 1 boot on`
(5) setup loop device failed `losetup -f`
(6) Create boot dir failed
(7) Mount a disk partition failed
(8) Copy files failed `cp`
(9) Unmount disk failed `umount`
(10) Detach loop device failed `losetup -d`
