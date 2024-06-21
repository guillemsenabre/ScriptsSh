#!/bin/bash


### CHECKUPS, CLEANUPS AND TRAPS ###

# Function to check if mkfs.ext4 is available and add /usr/sbin to PATH if needed
check_mkfs() {
	echo "-->checking mkfs is in PATH"
	if ! which mkfs >/dev/null 2>&1; then
		echo "-->mkfs not in path, adding /usr/sbin to PATH"
        	export PATH=$PATH:/usr/sbin
        fi
}

# Function to clean up resources
cleanup() {
	echo "Cleaning..."
	if [ $1 = "nok" ]; then
		if [ -f "/home/sipeed/restore/$DISK_IMG" ]; then
			echo "--> Removing $DISK_IMG"
			sudo rm -f $DISK_IMG || echo "-->Failed to remove $DISK_IMG"
		fi
	fi
        if [ -d "/recover" ]; then
		echo "--> Unmounting disk image from /recover"
        	sudo umount /recover || echo "-->Failed to unmount /recover"

		echo "--> Removing /recover directory"
		sudo rmdir /recover || echo "-->Failed to remove /recover directory"
        fi
        if [ -n "$LOOP_DEVICE" ]; then
		echo "--> Deataching loop device from $LOOP_DEVICE"
	        sudo losetup -d $LOOP_DEVICE || echo "-->Failed to detach loop device $LOOP_DEVICE"
        fi
}

# Set trap to call the cleanup function on script exit
trap 'EXIT_STATUS=$?; if [ $EXIT_STATUS -eq 0 -a $RSYNC_EXIT -eq 0 ]; then cleanup ok; else cleanup nok; fi' EXIT

# -------------------------------------------- #
### CONFIGURATION ###

# Machine
MACHINE="ln01"
echo "-->Machine set to $MACHINE"

# Backup path
BACKUP_PATH="/mnt/lichee_backups/${MACHINE}/latest/"
echo "-->Backup path set to $BACKUP_PATH"

# Disk image name
DISK_IMG=rootfs.ext4
echo "-->Disk image named as $DISK_IMG"

# Size of filesystem (output in MB and keeps numerical values only)
SIZE=$(sudo du -s --block-size M $BACKUP_PATH | awk '{print $1}' | grep -o '[0-9]\+')
echo "-->Size of filesystem is: $SIZE"

# Adding a safety factor of 500 MB
FS_SIZE=$(($SIZE + 500))
echo "-->Size of fs with safety factor added is: $FS_SIZE"



# -------------------------------------------- #
### IMAGE DISK CREATION ###

# Raw disk image from snapshot
echo "-->creating disk partition with dd"
dd if=/dev/zero of=$DISK_IMG bs=1M count=$FS_SIZE || { echo "-->Failed to create a disk partition"; exit 1; }

# Check if mkfs is in PATH and Format to ext4
check_mkfs

echo "-->formating disk partition"

mkfs.ext4 $DISK_IMG || { echo "-->Failed to format disk partition"; exit 1; }

# Create recover directory to mount disk image
echo "-->creating mount directory"
sudo mkdir /recover || { echo "-->Failed to create /recover directory"; exit 1; }

# setup loop device and mount disk image in /recover
LOOP_DEVICE=$(sudo losetup -fP --show $DISK_IMG)

echo "-->Filesystem set up in loop device: $LOOP_DEVICE"

# mount loop device in /recover mount directory
sudo mount $LOOP_DEVICE /recover

echo "-->$LOOP_DEVICE mounted in /recover"

# Copy (cp) snapshot filesystem in mounted device
echo "-->Copying $BACKUP_PATH int /recover"
sudo rsync -a ${BACKUP_PATH}/ /recover; RSYNC_EXIT=$?





















##### QEMU SETUP #####

#DISK="/mnt/lichee_backups/${MACHINE}/latest/boot/Image"
#KERNEL_FILE="u-boot-spl.bin"
#BIOS_FILE="fw_dynamic.bin"
#RAM=4G
#NUM_CPUS=2

#qemu-system-riscv64 \
#  -machine virt \
#  -nographic \
#  -m $RAM \
#  -smp $NUM_CPUS \
#  -bios $BIOS_FILE \
#  -kernel $KERNEL_FILE \
#  -drive file=$DISK,format=raw,if=virtio

