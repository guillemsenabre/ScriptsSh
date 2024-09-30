import multiprocessing
import time
import psutil
import argparse
from concurrent.futures import ProcessPoolExecutor

def simulate_user_load():
    """Simulate a user's workload."""
    # Replace this with a more realistic workload
    # For example, you could run a small PyTorch computation here
    start_time = time.time()
    while time.time() - start_time < 60:  # Run for 60 seconds
        _ = [i * i for i in range(10000)]

def monitor_system(duration):
    """Monitor system resources."""
    start_time = time.time()
    while time.time() - start_time < duration:
        cpu = psutil.cpu_percent(interval=1)
        mem = psutil.virtual_memory().percent
        print(f"CPU: {cpu}%, Memory: {mem}%")
        time.sleep(1)

def stress_test(num_users, duration):
    """Run the stress test."""
    print(f"Starting stress test with {num_users} simulated users for {duration} seconds")

    # Start the system monitor in a separate process
    monitor_process = multiprocessing.Process(target=monitor_system, args=(duration,))
    monitor_process.start()

    # Start the simulated user processes
    with ProcessPoolExecutor(max_workers=num_users) as executor:
        futures = [executor.submit(simulate_user_load) for _ in range(num_users)]

        # Wait for all processes to complete or for the duration to expire
        start_time = time.time()
        while time.time() - start_time < duration and not all(f.done() for f in futures):
            time.sleep(1)

    # Wait for the monitor to finish
    monitor_process.join()

    print("Stress test completed")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="RISC-V Machine Stress Test")
    parser.add_argument("--users", type=int, default=10, help="Number of simulated users")
    parser.add_argument("--duration", type=int, default=300, help="Duration of the test in seconds")
    args = parser.parse_args()

    stress_test(args.users, args.duration)
