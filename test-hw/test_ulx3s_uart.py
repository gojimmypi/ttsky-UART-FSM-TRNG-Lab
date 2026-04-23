import argparse
import sys
import time

import serial

EXPECTED_VERSION_PREFIX = b"Version "

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", required=True, help="Serial port, for example COM5 or /dev/ttyUSB0")
    parser.add_argument("--baud", type=int, default=115200, help="UART baud rate")
    parser.add_argument("--timeout", type=float, default=2.0, help="Read timeout in seconds")
    args = parser.parse_args()

    ser = serial.Serial(args.port, args.baud, timeout=args.timeout)
    try:
        ser.reset_input_buffer()
        ser.reset_output_buffer()

        time.sleep(0.1)

        ser.write(b"V\r")
        ser.flush()

        response = ser.read(128)

        print(f"Raw response: {response!r}")

        if EXPECTED_VERSION_PREFIX not in response:
            print("ERROR: expected version prefix not found")
            return 1

        print("PASS")
        return 0

    finally:
        ser.close()

if __name__ == "__main__":
    sys.exit(main())