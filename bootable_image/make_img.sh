#!/bin/sh

# Args check

if [ $# -ne 1 ]
then
	echo "Usage: $0 <filename>"
  	exit 1
fi

# Traps and Cleanup
trap 'sudo cleanup' EXIT

cleanup()
{
       sudo losetup -d "$loopdevice" 
       sudo umount /mnt/boot
       sudo umount /mnt/rootfs
}


# TODO - Change arguments to $1 $2 $3 ...
filename="$1"

# Path to kernel image
image_file=/home/gsenabre/Documents/buildroot_dirs/buildroot1/output/images/Image

# Path to OpenSBI firmware/bootloader
opensbi_fw=/home/gsenabre/Documents/buildroot_dirs/buildroot1/output/images/fw_ju>

# Path to root filesystem
rootfs_file=/home/gsenabre/Documents/buildroot_dirs/buildroot1/output/images/root>

# Define block size [Mi]
bs=1M

# Define block count
count=130

# table type can be gpt, msdos,...
table_type=gpt

# filesystem extension can be ext2, ext3, ext4.
fs_ext=ext2

# vfat partition is a bootable partition (efi?) fat32.
boot_part=vfat

# Create disk with $count blocks of size $bs -> size_of_disk = $bs * $count [MiB]
dd if=/dev/zero of="$filename" bs=$bs count=$count || exit 1

# Make 2 disk partitions using partition table $table_type
parted "$filename" --script mklabel $table_type || exit 2
parted "$filename" --script mkpart primary $boot_part 1M 25M || exit 3
parted "$filename" --script mkpart primary $fs_ext 25M 100% || exit 3

# Set boot flag
parted "$filename" --script set 1 boot on || exit 4 # Set boot flag on partition 1

# Setup loop device
loopdevice=$(losetup -f --show "$filename") || exit 5

# Mount partition 1 (bootable)
sudo mkdir -p /mnt/boot || exit 6
sudo mount "${loopdevice}p1" /mnt/boot || exit 7
sudo cp $image_file /mnt/boot || exit 8
sudo cp $opensbi_fw /mnt/boot || exit 8
sudo umount "${loopdevice}p1" || exit 9

# Mount partition 2 (filesystem)
sudo mkdir -p /mnt/rootfs || exit 6
sudo mount "${loopdevice}p2" /mnt/rootfs || exit 7
sudo cp $rootfs_file /mnt/rootfs || exit 8
sudo umount "${loopdevice}p2" || exit 9

# Detach loop device
sudo losetup -d "$loopdevice" || exit 10
