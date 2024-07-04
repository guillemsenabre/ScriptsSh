#!/bin/bash


### CHECKUPS, CLEANUPS AND TRAPS ###

# Function to check if mkfs.ext4 is available and add /usr/sbin to PATH if needed
ensure_path() {
	echo "INFO: checking mkfs and parted are in PATH"
	if ! which mkfs >/dev/null 2>&1 || ! which parted >/dev/null 2>&1; then
		echo "INFO: mkfs or parted not in path, adding /usr/sbin to PATH"
        	export PATH=$PATH:/usr/sbin
        fi
}


# Function to clean up resources
cleanup() {
	echo "Cleaning..."
	if [ $1 = "nok" ]; then
		if [ -f "/home/sipeed/restore/$DISK_IMG" ]; then
			echo "INFO:  Removing $DISK_IMG"
			sudo rm -f $DISK_IMG || echo "INFO: Failed to remove $DISK_IMG"
		fi
	fi
        if [ -d "/recover" ]; then
		echo "INFO:  Unmounting disk image from /recover"
        	sudo umount /recover/rootfs || echo "INFO: Failed to unmount /recover/rootfs (p1)"
		sudo umount /recover/boot || echo "INFO: Failed to unmount /recover/boot (p2)"

		echo "INFO:  Removing /recover directory"
		sudo rm -rf /recover || echo "INFO: Failed to remove /recover directory"
        fi
        if [ -n "$LOOP_DEVICE" ]; then
		echo "INFO:  Detaching loop device from $LOOP_DEVICE"
	        sudo losetup -d $LOOP_DEVICE || echo "INFO: Failed to detach loop device $LOOP_DEVICE"
        fi
}

# Set trap to call the cleanup function on script exit
trap 'EXIT_STATUS=$?; if [ $EXIT_STATUS -eq 0 -a $RSYNC_EXIT -eq 0 ]; then cleanup ok; else cleanup nok; fi' EXIT

# -------------------------------------------- #
### CONFIGURATION ###

# Initialize rsync exit status
RSYNC_EXIT=0

# Machine
MACHINE="ln01"
echo "INFO: Machine set to $MACHINE"

# Backup path
#BACKUP_PATH="/mnt/lichee_backups/${MACHINE}/latest/"
BACKUP_PATH="/mnt/lichee_backups/test/${MACHINE}/latest/"

echo "INFO: Backup path set to $BACKUP_PATH"

# Disk image name
DISK_IMG=rootfs_test.ext4
echo "INFO: Disk image named as $DISK_IMG"

# Size of filesystem (output in MB and keeps numerical values only)
SIZE=$(sudo du -s --block-size M $BACKUP_PATH | awk '{print $1}' | grep -o '[0-9]\+')
echo "INFO: Size of filesystem is: $SIZE"

# Adding a safety factor of 500 MB
FS_SIZE=$(($SIZE + 500))
echo "INFO: Size of fs with safety factor added is: $FS_SIZE"

# Table type (gpt, mdos,...)
TABLE=gpt



# -------------------------------------------- #
### IMAGE DISK CREATION ###

# Raw disk image from snapshot
echo "INFO: creating disk partition with dd"
dd if=/dev/zero of=$DISK_IMG bs=1M count=$FS_SIZE || { echo "INFO: Failed to create a disk partition"; exit 1; }

# Check if parted and mkfs are in PATH
ensure_path

# Use partition table defined in TABLE variable
echo "INFO: creating disk partition"
parted $DISK_IMG --script mklabel $TABLE || { echo "INFO: Partition table failed, exiting..."; exit 1; }

# Format partition 1 as ext4 (doesn't create a fs yet)
echo "INFO: formating disk partition"
parted $DISK_IMG --script mkpart primary ext4 1MiB 50MiB || { echo "INFO: Failed to create partition 1"; exit 1; }
parted $DISK_IMG --script mkpart primary ext4 50MiB 100% || { echo "INFO: Failed to create partition 2"; exit 1; }

# Create recover directory to mount disk image
echo "INFO: creating mount directories"
sudo mkdir -p /recover /recover/boot /recover/rootfs || { echo "INFO: Failed to create /recover directory"; exit 1; }

# setup loop device and mount disk image in /recover
LOOP_DEVICE=$(sudo losetup -fP --show $DISK_IMG) || { echo "INFO: failed to set up a loop device, exiting..."; exit 1; }

echo "INFO: Filesystem set up in loop device: $LOOP_DEVICE"

# Store the first partition of the loop device to be used later
PARTITION_1="${LOOP_DEVICE}p1"
PARTITION_2="${LOOP_DEVICE}p2"

# Create an ext4 filesystem on partition 1 (journaling,....)
echo "INFO: Creating ext4 filesystem on partition 1"
sudo mkfs.ext4 $PARTITION_1 || { echo "INFO: Failed to format disk partition 1"; exit 1; }
sudo mkfs.ext4 $PARTITION_2 || { echo "INFO: Failed to format disk partition 2"; exit 1; }

# Make partition 1 bootable
sudo parted $PARTITION_1 set 1 boot on || { echo "INFO: Failed to set partition 1 as bootable"; exit 1; }

# mount partition 1 in /recover mount directory
sudo mount $PARTITION_1 /recover/boot
sudo mount $PARTITION_2 /recover/rootfs

echo "INFO: ${LOOP_DEVICE}p1 mounted in /recover/boot"
echo "INFO: ${LOOP_DEVICE}p2 mounted in /recover/rootfs"

# Copying Linux Kernel in /recover/boot
echo "INFO: copying kernel image in /recover/boot"
sudo cp ${BACKUP_PATH}/boot/Image /recover/boot

# Copy (rsync) snapshot filesystem in mounted device
echo "INFO: copying root filesystem in /recover/rootfs (partition 2)"
sudo rsync -aAXHS ${BACKUP_PATH}/ /recover/rootfs; RSYNC_EXIT=$?

# Ensure data is written and cleanup
sync
