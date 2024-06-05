#!/bin/sh

# Args check

if [ $# -ne 1 ]
then
	echo "Usage: $0 <filename>"
  	exit 1
fi

# Traps and Cleanup ------------------

# Trap will be executed whenever the script exits
# Cleanup will
#(1) Detach loop devices
#(2) unmount both partitions
#(3) remove created dirs and
#(4) remove .img file

# Set trap to call the cleanup function on script exit
trap 'if [ $? -ne 0 ]; then cleanup; fi' EXIT

cleanup()
{
	echo "Starting cleanup..."
	sudo losetup -d "$loopdevice"
        sudo umount /mnt/boot
        sudo umount /mnt/rootfs
	sudo rm -rf /mnt/boot /mnt/rootfs
	sudo rm ${curr}/${filename}
}

# ------------------------------------

# Configuration and variables --------

# Save current directory
curr=$(pwd)

# TODO - Change arguments to $1 $2 $3 ...
filename="$1"

# Path to dir where the .img will be stored
out_dir=/home/gsenabre/images/test_img_buildroot/

# Path to kernel image
image_file=/home/gsenabre/Documents/buildroot_dirs/buildroot1/output/images/Image

# Path to OpenSBI firmware/bootloader
opensbi_fw=/home/gsenabre/Documents/buildroot_dirs/buildroot1/output/images/fw_jump.elf

# Path to root filesystem
rootfs_file=/home/gsenabre/Documents/buildroot_dirs/buildroot1/output/images/rootfs.tar

# Define block size [Mi]
bs=1M

# Define block count
count=130

# table type can be gpt, msdos,...
table_type=gpt

# filesystem extension can be ext2, ext3, ext4.
fs_ext=ext2

# vfat format is an extension of fat32. Both are supported by UEFI systems.
boot_part=fat32
boot_format=vfat

# -----------------------------------

# Building disk image ---------------

# Create disk with $count blocks of size $bs -> size_of_disk = $bs * $count [MiB]
dd if=/dev/zero of="$filename" bs=$bs count=$count || exit 1

# Make 2 disk partitions using partition table $table_type
parted "$filename" --script mklabel $table_type || exit 2
parted "$filename" --script mkpart primary $boot_part 1MiB 25MiB || exit 3
parted "$filename" --script mkpart primary $fs_ext 25MiB 100% || exit 3

# Set esp (for UEFI sys, like OpenSBI) flag on partition 1
parted "$filename" --script -- set 1 esp on || exit 4

# Setup loop device
loopdevice=$(losetup -f --show "$filename") || exit 5

# Inform the OS of partition table changes on the loop device
partprobe $loopdevice

# Format partitions vfat/fat32 (p1 (boot)) and ext2 (p2 (fs))
mkfs.${boot_format} ${loopdevice}p1
mkfs.${fs_ext} ${loopdevice}p2

echo "partitions formatted"


# Partition 1 ------------------------

# Create dir boot in mount to mount partition 1
mkdir -p /mnt/boot || exit 6

# Mount partition 1 in /mnt/boot
mount "${loopdevice}p1" /mnt/boot || exit 7

# Copy kernel image and firmware (opensbi?) in mnt/boot
cp $image_file /mnt/boot || exit 8
cp $opensbi_fw /mnt/boot || exit 8

# Debug & info
echo "Content of /mnt/boot after mount and copy:"
ls -lh /mnt/boot

# Umount /mnt/boot
umount "${loopdevice}p1" || exit 9
echo "Partition 1 ok"

# Partition 2 ------------------------

# Create dir rootfs in mount to mount partition 2
mkdir -p /mnt/rootfs || exit 6

# Mount partition 2 in /mnt/rootfs
mount "${loopdevice}p2" /mnt/rootfs || exit 7

# If using rootfs.ext2 (or other extension) use dd to copy files into the mounted device
#dd if=$rootfs_file of=/mnt/rootfs/rootfs.ext2 bs=1M || exit 8

# IF using rootfs.tar, decompress the file into the mounted device
tar -xf $rootfs_file -C /mnt/rootfs || exit 11

# Debug & info
echo "Content of /mnt/rootfs after mount and copy:"
ls /mnt/rootfs

# Unmount /mnt/rootfs
umount "${loopdevice}p2" || exit 9

echo "Partition 2 ok"

# ------------------------------------

# Detach loop device
losetup -d "$loopdevice" || exit 10

echo "$loopdevice detached"

# Change owner to gsnabre (hardcoded)
chown gsenabre:gsenabre "$filename" || exit 12

# Move .img to output directory
mv "$filename" $out_dir
