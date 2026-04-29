#!/usr/bin/env python3

import serial
import time
import argparse
import sys


def read_lines(port, baud, max_lines, timeout_seconds):
    try:
        ser = serial.Serial(port, baudrate=baud, timeout=0.1)
    except serial.SerialException as e:
        print(f"ERROR: Unable to open port {port}: {e}")
        return 1

    lines = []
    start_time = time.time()

    while True:
        # Check global timeout
        if (time.time() - start_time) >= timeout_seconds:
            print("Timeout reached")
            break

        # Read line (non-blocking due to timeout=0.1)
        try:
            raw = ser.readline()
        except serial.SerialException as e:
            print(f"ERROR: Serial read failed: {e}")
            break

        if raw:
            try:
                line = raw.decode("ascii", errors="replace").rstrip("\r\n")
            except Exception:
                line = str(raw)

            except KeyboardInterrupt:
                print("\nInterrupted by user")

            print(line)
            lines.append(line)

            if len(lines) >= max_lines:
                print("Reached requested line count")
                break

    ser.close()

    print(f"Total lines read: {len(lines)}")
    return 0


def main():
    parser = argparse.ArgumentParser(description="Read N lines from ULX3S ESP32 UART")
    parser.add_argument("--port", required=True, help="Serial port (e.g., COM5 or /dev/ttyUSB0)")
    parser.add_argument("--baud", type=int, default=115200, help="Baud rate (default: 115200)")
    parser.add_argument("--lines", type=int, default=10, help="Number of lines to read")
    parser.add_argument("--timeout", type=float, default=5.0, help="Total timeout in seconds")

    args = parser.parse_args()

    return read_lines(args.port, args.baud, args.lines, args.timeout)


if __name__ == "__main__":
    sys.exit(main())
