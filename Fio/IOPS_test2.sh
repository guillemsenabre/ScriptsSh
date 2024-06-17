#!/bin/bash

# Log directory
log_dir=/var/log/fio/

# Device to benchmark
dev_path=/mnt

# Change to device path and run fio
cd ${dev_path} || { echo "failed to change directory to /mnt"; exit 1; }

# Instead, you can use the flag --blocksize-range or --bsrange!
bs_test=(64)


# Test different bs
## Smaller puts more stress on IOPS, bigger puts more stress on Throughput)
for bs in ${bs_test[@]}
do
	echo "Testing IOPS with bs=${bs}"
	sudo fio --name=randread${bs} \
		 --bs=${bs}K \
		 --rw=randread \
		 --size=4g \
		 --iodepth=256 \
		 --ioengine=posixaio \
		 --time_based \
		 --runtime=60 \
		 --numjobs=4 \
		 > ${log_dir}IOPS_bs${bs}.log

	# Check if fio command succeeded
	if [ $? -ne 0 ]
	then
        	echo "fio test failed for block size ${bs}K. Check ${log_dir}IOPS_bs${bs}.log for details."
	        exit 1
    	fi
done



