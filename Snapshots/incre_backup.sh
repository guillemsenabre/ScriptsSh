#!/bin/bash

#** VARIABLES **#

# Backup path for testing purposes
test=/home/sipeed/testdir/
#fullbk=/

# Array of nodes to be backed up (user is always "sipeed", if not, change variable to array).
# Can be changed by IP addresses as well -> new backup dirs' name will change
nodes=(ln01 ln02 ln03 ln04 controller)

# Change between test (test files) or fullbk (all fs)
dir_to_back_up=$test

# Path to save backup files from all nodes
backup_dir=/mnt/lichee_backups


#** LOGIC **#
check_backup()
{
	if [ $? -eq 0 ]; then
       		echo "--> $1 backup successful!"
	else
       		echo "--> Something went wrong... Try again later"
	fi
}

backup()
{
	local dated=$(date "+%d%m%y_%H%M")
	local node=$1
	local backup_node_dir=${backup_dir}/${node}/"${node}_${dated}"
	local latest_link_path=${backup_dir}/${node}/latest

	echo "Backing up $node"

	echo "--> Creating directory: $backup_node_dir"
	mkdir $backup_node_dir

        echo "--> Backing up directory $dir_to_back_up of node $node"
	rsync -azvv -e ssh \
	      	--rsync-path="sudo rsync" \
	      	--link-dest="${latest_link_path}" \
	      	--exclude="/dev/*" \
	      	--exclude="/proc/*" \
	      	--exclude="/sys/*" \
	      	--exclude="/tmp/*" \
	      	--exclude="*lost+found" \
	      	sipeed@$node:$dir_to_back_up \
	      	$backup_node_dir

        check_backup $node

	echo "--> Updating latest link..."
	rm -rf "$latest_link_path"
	ln -s "$backup_node_dir" "$latest_link_path"
}

echo "Running backups. Tail /var/log/backup/backup.log to watch stdout"

for node in ${nodes[@]}
do
        ssh -o ConnectTimeout=5 sipeed@$node exit &> /dev/null
        if [ $? -ne 0 ]; then
                echo "--> Failed to connect to $node. Check SSH connection."
                continue
	fi

	echo "Backing up $node"

	# Run backup method and redirect std to its respective log files
	backup $node \
		2>> /var/log/backup/backup_error.log \
		1>> /var/log/backup/backup.log \
		1> /var/log/backup/backup_last.log
done

echo "All backups completed!"

