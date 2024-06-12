#!/bin/bash

#####################################################################
# WARNING: THIS SCRIPT WILL DELETE ALL BACKUPS IF USED WITH ARG <d> #
#####################################################################


show()
{
	echo "$item"
}

delete()
{
	echo "removing $item"
	rm -rf $item
}

# Check if an argument is provided
if [ -z "$1" ]; then
    echo "No arguments provided. Args: <s>, <d>, <l>, <lf>, <lerr>"
    exit 1
fi

# Print logs with arg <l>, <lerr>
if [ $1 = "lerr" ]
then
	cat /var/log/backup/backup_error.log
	exit 0
elif [ $1 = "lf" ]
then
	cat /var/log/backup/backup.log
        exit 0
elif [ $1 = "l" ]
then
        cat /var/log/backup/backup_last.log
        exit 0
fi

# Show content or remove files depending on args
for dir in /mnt/lichee_backups/*
do
        for item in ${dir}/*
        do
		if [ $1 = "s" ]
		then
			show
		elif [ $1 = "d" ]
		then
			delete
		else
			echo "Wrong args. Args: <s>, <d>, <l>, <lerr>"
		fi
	done
done

