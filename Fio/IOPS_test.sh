#!/bin/bash

which_test()
{
	local options=$1

	# Change to /mnt (where sda1 is mounted) and run fio
	cd /mnt || { echo "failed to change directory to /mnt"; exit 1; }

	echo "Running rand${options}_IOPS.fio" \
       	&& echo "tail /var/fio/rand${options}_IOPS.log to watch stdout" \
	&& sudo fio /home/sipeed/fio_scripts/rand${options}_IOPS.fio >> /var/log/fio/rand${options}_IOPS.log
}





case $1 in
	rw)
		which_test RW
	;;

        frw)
		which_test FRW
        ;;

        r)
		which_test R
        ;;

        sr)
		which_test SR
        ;;

        all)
		which_test R
		which_test RW
		which_test FRW
		which_test SR
        ;;

	*)
		echo "args <rw> <frw> <r> <sr>"
		exit 1
	;;
esac
