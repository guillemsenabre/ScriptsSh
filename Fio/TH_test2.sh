#!/bin/bash

# Log directory
log_dir=/var/log/fio/TH/

# Device to benchmark
dev_path=/mnt

# Change to device path and run fio
cd ${dev_path} || { echo "failed to change directory to /mnt"; exit 1; }

# Instead, you can use the flag --blocksize-range or --bsrange! (in KB)
iodepth_test=(64 128 256 512)


# Test different iodepths
## Smaller puts more stress on IOPS, bigger puts more stress on Throughput)
for iodepth in ${iodepth_test[@]}
do
        echo "Testing Throughput with iodepth=${iodepth}"
        sudo fio --name=randread${bs} \
                 --bs=256K \
                 --rw=randread \
                 --size=4g \
                 --iodepth=256 \
                 --ioengine=posixaio \
                 --time_based \
                 --runtime=60 \
                 --numjobs=4 \
                 > ${log_dir}TH_iodepth${iodepth}.log

        # Check if fio command succeeded
        if [ $? -ne 0 ]
        then
                echo "fio test failed for depth of ${iodepth}K. Check ${log_dir}IOPS_bs${iodepth}.log for details."
                exit 1
        fi
done
