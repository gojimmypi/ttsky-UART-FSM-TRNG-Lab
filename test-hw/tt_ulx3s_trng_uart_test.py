#!/usr/bin/env python3

import argparse
import time
import serial


def send_cmd(ser, cmd):
    ser.write((cmd + "\r\n").encode("ascii"))
    ser.flush()
    time.sleep(0.10)

    out = ser.read_all().decode("ascii", errors="replace")
    if out:
        print(out, end="")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", required=True)
    parser.add_argument("--baud", type=int, default=115200)
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

    with serial.Serial(args.port, args.baud, timeout=0.2) as ser:
        time.sleep(0.2)
        ser.reset_input_buffer()

        for cmd in commands:
            print(">> " + cmd)
            send_cmd(ser, cmd)


if __name__ == "__main__":
    main()