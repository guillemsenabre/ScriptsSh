#!/bin/bash

# Check if exactly two arguments (directories) are provided
if [ "$#" -ne 2 ]; then
	echo "Usage: $0 <directory1> <directory2>"
	exit 1
fi

# Assign directories from arguments
DIR1="$1"
DIR2="$2"

# Function to check if directory provided as an argument is truly a directory
is_directory() {
	if [ ! -d $1 ]; then
		echo "Error: $1 is not a valid directory."
		exit 1
	fi
}

# Function to count files excluding those that begin with a dot
count_files() {
	local dir="$1"
	find "$dir" -maxdepth 1 -type f ! -name ".*" | wc -l
}


# Function to count missing files from on directory to another
file_in_directory() {
	local file=$1
	local filename=$(basename "$file")
        if [ -e ${min_dir}/${file} ]; then
                echo "INFO: ${filename}... OK!"
		((ok++))
        else
                echo "INFO: ${filename} NOT FOUND in ${min_dir}!"
        	((not_found++))
	fi
}

# Function to check the contents of files in both directories
files_have_same_content() {
	local file=$1
        local filename=$(basename "$file")
	if cmp -s "$file" "$min_dir/$filename"; then
		echo "INFO: ${filename} is the same in both directories."
	else
                echo "INFO: ${filename} differs in contents."
        fi
}

# Check if the first argument is a directory
is_directory $DIR1

# Check if the second argument is a directory
is_directory $DIR2


# Count the number of files in each directory
count1=$(count_files "$DIR1")
count2=$(count_files "$DIR2")

# Output the counts
echo "INFO: Number of files in $DIR1: $count1"
echo "INFO: Number of files in $DIR2: $count2"

# Compare the file counts
if [ "$count1" -gt "$count2" ]; then
	echo "INFO: $DIR1 has more files than $DIR2."
	max_dir=$DIR1
	min_dir=$DIR2
elif [ "$count1" -lt "$count2" ]; then
	echo "INFO: $DIR2 has more files than $DIR1."
	max_dir=$DIR2
	min_dir=$DIR1
else
	echo "INFO: $DIR1 and $DIR2 have the same number of files."
fi

# Initialize counters
ok=0
not_found=0

# Compare which files are missing in the lesser count's directory
for file in $max_dir/*
do
	file_in_directory $file
done

echo "INFO: Shared files: $ok"
echo "INFO: $min_dir doesn't contain $not_found files from $max_dir"


# Compare contents of files in both directories
#for file in $max_dir
#do
#	files_have_same_content $file
#done

