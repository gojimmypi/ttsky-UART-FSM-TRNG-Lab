#!/usr/bin/env python3

import argparse
import sys
import time

import serial


def hex_bytes(data):
    return " ".join("{:02X}".format(value) for value in data)


def parse_args():
    parser = argparse.ArgumentParser(
        description="UART loopback test with optional inter-byte TX delay."
    )

    parser.add_argument("--port", required=True)
    parser.add_argument("-b", "--baud", type=int, default=115200)
    parser.add_argument("--timeout", type=float, default=2.0)
    parser.add_argument("--quiet", type=float, default=0.10)
    parser.add_argument("--tx-delay", type=float, default=0.001)
    parser.add_argument("--repeat", type=int, default=1)
    parser.add_argument("--message", default="Hello loopback\r\n")

    return parser.parse_args()


def read_until_quiet(ser, timeout, quiet):
    data = bytearray()
    start_time = time.time()
    last_rx_time = None

    while True:
        now = time.time()

        if now - start_time > timeout:
            break

        count = ser.in_waiting

        if count > 0:
            chunk = ser.read(count)
            data.extend(chunk)
            last_rx_time = time.time()
            continue

        if last_rx_time is not None:
            if now - last_rx_time >= quiet:
                break

        time.sleep(0.001)

    return bytes(data)


def write_with_delay(ser, data, delay):
    for value in data:
        ser.write(bytes([value]))
        ser.flush()

        if delay > 0.0:
            time.sleep(delay)


def show_result(tx_data, rx_data):
    print("TX text:", repr(tx_data))
    print("TX hex: ", hex_bytes(tx_data))
    print("RX text:", repr(rx_data))
    print("RX hex: ", hex_bytes(rx_data))

    if rx_data == tx_data:
        print("PASS")
        return True

    print("FAIL")

    min_len = min(len(tx_data), len(rx_data))

    for index in range(min_len):
        if tx_data[index] != rx_data[index]:
            print(
                "First mismatch at byte {}: expected 0x{:02X}, got 0x{:02X}".format(
                    index,
                    tx_data[index],
                    rx_data[index]
                )
            )
            break

    if len(rx_data) != len(tx_data):
        print("Expected length:", len(tx_data))
        print("Actual length:  ", len(rx_data))

    return False


def main():
    args = parse_args()

    tx_data = args.message.encode("ascii")

    try:
        with serial.Serial(
            port=args.port,
            baudrate=args.baud,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE,
            timeout=0,
            write_timeout=2,
            xonxoff=False,
            rtscts=False,
            dsrdtr=False
        ) as ser:
            print("Port:", args.port)
            print("Baud:", args.baud)
            print("TX delay:", args.tx_delay)

            time.sleep(0.2)

            all_ok = True

            for test_index in range(args.repeat):
                print("")
                print("Test {}/{}".format(test_index + 1, args.repeat))

                ser.reset_input_buffer()
                ser.reset_output_buffer()

                time.sleep(0.05)

                write_with_delay(ser, tx_data, args.tx_delay)

                rx_data = read_until_quiet(
                    ser,
                    args.timeout,
                    args.quiet
                )

                if not show_result(tx_data, rx_data):
                    all_ok = False

            if all_ok:
                return 0

            return 1

    except serial.SerialException as exc:
        print("Serial error:", exc)
        return 2
    except KeyboardInterrupt:
        print("")
        print("Interrupted")
        return 130


if __name__ == "__main__":
    sys.exit(main())