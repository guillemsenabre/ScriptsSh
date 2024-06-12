#!/bin/bash

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
    echo "No arguments provided. Args: <s>, <d> or <sd>"
    exit 1
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
			echo "Wrong args. Args: <s>, <d> or <sd>"
		fi
	done
done
