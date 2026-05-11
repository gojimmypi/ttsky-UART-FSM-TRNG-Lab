#!/usr/bin/env python3

import argparse
import time

import serial


def read_until_idle(ser, idle_time, max_time):
    data = bytearray()
    start_time = time.monotonic()
    last_rx_time = start_time

    while True:
        chunk = ser.read(1)
        now = time.monotonic()

        if chunk:
            data.extend(chunk)
            last_rx_time = now
            continue

        if data and ((now - last_rx_time) >= idle_time):
            break

        if (now - start_time) >= max_time:
            break

    return bytes(data)


def send_cmd(ser, cmd, args):
    command = (cmd + "\r").encode("ascii")

    ser.reset_input_buffer()
    ser.write(command)
    ser.flush()

    response = read_until_idle(ser, args.idle_time, args.timeout)

    print(">> " + cmd)

    if response:
        print(response.decode("ascii", errors="replace"))
    else:
        print("(no response)")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", required=True)
    parser.add_argument("--baud", type=int, default=115200)
    parser.add_argument("--timeout", type=float, default=2.0)
    parser.add_argument("--idle-time", type=float, default=0.05)
    args = parser.parse_args()

    commands = [
        "E0",
        "S0",
        "D01",
        "O00",
        "E1",
        "R6",
        "R7",
        "R6",
        "R7",
        "R6",
        "R7",
        "E0",
        "D40",
        "E1",
        "R6",
        "R7",
        "R6",
        "R7",
        "R6",
        "R7",
    ]

    ser = serial.Serial(args.port, args.baud, timeout=0.01)

    try:
        ser.reset_input_buffer()
        ser.reset_output_buffer()

        time.sleep(0.1)

        for cmd in commands:
            send_cmd(ser, cmd, args)

    finally:
        ser.close()


if __name__ == "__main__":
    main()