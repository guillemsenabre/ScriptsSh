#!/bin/bash

#** VARIABLES **#

# Backup path for testing purposes
test=/home/sipeed/testdir/

# Backup all fs
fullbk=/

# Source node (the one it's backing up its data) info
source_user=sipeed
#source_host=ln01

# Array of nodes to be backed up (user is always "sipeed", if not, change variable to array).
# Can be changed by IP addresses as well.
nodes=(ln01 ln02 ln03 ln04 controller)

# Change between test (test files) or fullbk (all fs)
dir_to_back_up=$test

# Path to save backup files from all nodes
dest_dir=/mnt/lichee_backups


#** LOGIC **#
check_backup()
{
	if [ $? -eq 0 ]; then
       		echo "--> $1 backup successful!"
	else
       		echo "--> Something went wrong... Try again later"
	fi
}

full_backup()
{
	local date=$(date "+%d_%m_%y_%R")
	local node=$1
	local dest_file_path=${dest_dir}/${node}/"${node}_${date}_fullbckp"
	echo "--> Creating directory: $dest_file_path"
	mkdir $dest_file_path
        echo "--> Backing up directory $dir_to_back_up of node $node"
        rsync -azvv -e ssh --rsync-path="sudo rsync"  $source_user@$node:$dir_to_back_up $dest_file_path
        check_backup $node
}


for node in ${nodes[@]}
do
        ssh -o ConnectTimeout=5 $source_user@$node exit &> /dev/null
        if [ $? -ne 0 ]; then
                echo "--> Failed to connect to $node. Check SSH connection."
                continue
	fi

	full_backup $node
done
