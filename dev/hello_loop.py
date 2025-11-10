#!/usr/bin/env python3
"""
Hello.py with infinite loop - printing every 30 seconds
"""
import time


def main():
    counter = 0
    while True:
        counter += 1
        print(f"[{counter}] Hello World from Railway!")
        print(f"Time: {time.strftime('%H:%M:%S')}")
        print("=" * 40)
        time.sleep(30)  # Wait 30 seconds


if __name__ == "__main__":
    main()


