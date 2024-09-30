#!/bin/bash


# Check if a username was provided
if [ "$#" -ne 1 ]; then
	echo "usage: riscv-stress-test.sh <username>"
	exit 1
fi

username=$1

# Simulate user load
simulate_load() {
	while true; do
		# CPU-intensive task
        	for i in {1..10000}; do
            		echo "scale=10; s($i) * s($i)" | bc -l > /dev/null
			[ $((i%10)) -eq 0 ] && echo "$i"
        	done
	        # I/O-intensive task
        	## dd if=/dev/zero of=/tmp/iotest bs=64k count=16k conv=fdatasync >/dev/null 2>&1
	        # Short sleep to prevent 100% CPU usage
        	sleep 0.1
	done
}

# Run the load on the specified user provided by arg1 ($1)
sudo -u $username bash -c "$(declare -f simulate_load); simulate_load" &

echo "Loadstarted for user $username. PID: $!"
echo "To stop de load, run: kill $!"
