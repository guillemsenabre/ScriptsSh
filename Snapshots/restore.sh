#!/bin/bash

# - TODO - CHECK THAT MKFS IS AVAILABLE, IF NOT, ADD /USR/SBIN TO PATH
# - TODO - CLEANUP FUNCTION -> UNMOUNT, DELETE MKDIRS,...

# Function to check if mkfs.ext4 is available and add /usr/sbin to PATH if needed
check_mkfs() {
    if ! command -v mkfs.ext4 &> /dev/null; then
        export PATH=$PATH:/usr/sbin
    fi
}

# Function to clean up resources
cleanup() {
    if [ -d "/recover" ]; then
        sudo umount /recover || echo "Failed to unmount /recover"
        sudo rmdir /recover || echo "Failed to remove /recover directory"
    fi
    if [ -n "$LOOP_DEVICE" ]; then
        sudo losetup -d $LOOP_DEVICE || echo "Failed to detach loop device $LOOP_DEVICE"
    fi
}

# Set trap to call the cleanup function on script exit
trap 'if [ $? -ne 0 ]; then cleanup; fi' EXIT



# Machine
MACHINE="ln01"

# Backup path
BACKUP_PATH="/mnt/lichee_backups/${MACHINE}/latest"

# Size of filesystem (output in MB and keeps numerical values only)
SIZE=$(sudo du -s --block-size M | awk '{print $1}' | grep -o '[0-9]\+')

# Adding a safety factor of 100 MB
FS_SIZE=$(($SIZE + 100))

# Raw disk image from snapshot
dd if=/dev/zero of=rootfs.ext4 bs=1M count=$FS_SIZE

# Format to ext4
mkfs.ext4 rootfs.ext4

# Create recover directory to mount disk image
sudo mkdir /recover

# - TODO - Make sure /recover has been created (#?)

# setup loop device and mount disk image in /recover
LOOP_DEVICE=$(sudo losetup -fP --show test.img)
echo "Filesystem set up in loop device: $LOOP_DEVICE"

# mount loop device in /recover mount directory
echo "Mounting $LOOP_DEVICE in /recover"
sudo mount $LOOP_DEVICE /recover


# Copy (cp) snapshot filesystem in mounted device
echo "Copying $BACKUP_PATH int /recover"
sudo rsync -a ${BACKUP_PATH}/* /recover

# Unmount and detach the filesystem
sudo umount /recover
sudo losetup -d $LOOP_DEVICE























##### QEMU SETUP #####

DISK="/mnt/lichee_backups/${MACHINE}/latest/boot/Image"
KERNEL_FILE="u-boot-spl.bin"
BIOS_FILE="fw_dynamic.bin"
RAM=4G
NUM_CPUS=2

#qemu-system-riscv64 \
#  -machine virt \
#  -nographic \
#  -m $RAM \
#  -smp $NUM_CPUS \
#  -bios $BIOS_FILE \
#  -kernel $KERNEL_FILE \
#  -drive file=$DISK,format=raw,if=virtio

