#!/usr/bin/env python3

import argparse
import sys
import time

import serial


def parse_args():
    parser = argparse.ArgumentParser(
        description="Test UART loopback by sending bytes and expecting the same bytes back."
    )

    parser.add_argument(
        "-p",
        "--port",
        help="Serial port, for example COM7 or /dev/ttyUSB0"
    )

    parser.add_argument(
        "-b",
        "--baud",
        type=int,
        default=115200,
        help="Baud rate. Default: 115200"
    )

    parser.add_argument(
        "-t",
        "--timeout",
        type=float,
        default=1.0,
        help="Read timeout in seconds. Default: 1.0"
    )

    parser.add_argument(
        "-m",
        "--message",
        default="Hello loopback\r\n",
        help="Message to send. Default: 'Hello loopback\\r\\n'"
    )

    parser.add_argument(
        "-n",
        "--repeat",
        type=int,
        default=1,
        help="Number of test repeats. Default: 1"
    )

    return parser.parse_args()


def read_exact(ser, count):
    data = bytearray()
    deadline = time.time() + ser.timeout

    while len(data) < count:
        if time.time() > deadline:
            break

        chunk = ser.read(count - len(data))

        if chunk:
            data.extend(chunk)

    return bytes(data)


def run_test(args):
    tx_data = args.message.encode("ascii")

    with serial.Serial(args.port, args.baud, timeout=args.timeout) as ser:
        ser.reset_input_buffer()
        ser.reset_output_buffer()

        time.sleep(0.1)

        for index in range(args.repeat):
            ser.reset_input_buffer()

            print("Test {}/{}".format(index + 1, args.repeat))
            print("TX:", tx_data)

            ser.write(tx_data)
            ser.flush()

            rx_data = read_exact(ser, len(tx_data))

            print("RX:", rx_data)

            if rx_data != tx_data:
                print("FAIL: loopback mismatch")
                print("Expected:", tx_data)
                print("Actual:  ", rx_data)
                return 1

            print("PASS")

    return 0


def main():
    args = parse_args()

    try:
        return run_test(args)
    except serial.SerialException as exc:
        print("Serial error:", exc)
        return 2
    except KeyboardInterrupt:
        print("")
        print("Interrupted")
        return 130


if __name__ == "__main__":
    sys.exit(main())