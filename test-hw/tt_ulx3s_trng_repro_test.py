#!/usr/bin/env python3
#
# Copyright (c) 2026 gojimmypi
# SPDX-License-Identifier: Apache-2.0
#
# file: tt_ulx3s_trng_repro_test.py

import argparse
import re
import sys
import time

import serial


READ_RE = re.compile(rb"R([0-7])=([0-9A-F]{2})\r")


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


def send_command(ser, command, args):
    ser.reset_input_buffer()
    ser.write(command)
    ser.flush()

    return read_until_idle(ser, args.idle_time, args.timeout)


def expect_ok(name, response):
    if response != b"OK\r":
        print(f"FAIL: {name}")
        print("  Expected: b'OK\\r'")
        print(f"  Actual:   {response!r}")
        return False

    return True


def write_ok(ser, args, name, command):
    response = send_command(ser, command, args)
    return expect_ok(name, response)


def read_reg(ser, args, reg_num):
    command = f"R{reg_num}\r".encode("ascii")
    response = send_command(ser, command, args)

    match = READ_RE.fullmatch(response)

    if not match:
        print(f"FAIL: R{reg_num} read")
        print(f"  Actual: {response!r}")
        return None

    return int(match.group(2), 16)


def configure_lfsr_test_mode(ser, args):
    ok = True

    # Disable sampling before changing configuration.
    ok = write_ok(ser, args, "E0 disable", b"E0\r") and ok

    # Pulse TRNG internal reset through reg_ctrl[2].
    ok = write_ok(ser, args, "W1 assert TRNG reset", b"W1\r") and ok
    ok = write_ok(ser, args, "W0 release TRNG reset", b"W0\r") and ok

    # Select source 0:
    # SRC_LFSR deterministic test source.
    ok = write_ok(ser, args, "S0 select LFSR", b"S0\r") and ok

    # Disable all ring oscillators.
    # This keeps the test purely digital and deterministic.
    ok = write_ok(ser, args, "O00 disable oscillators", b"O00\r") and ok

    # Use fast sample divider.
    ok = write_ok(ser, args, "D01 set divider", b"D01\r") and ok

    return ok


def capture_sample(ser, args):
    ok = True

    # Enable sampling long enough for the core to update.
    ok = write_ok(ser, args, "E1 enable sampling", b"E1\r") and ok

    # Freeze R6/R7 so the pair is coherent.
    ok = write_ok(ser, args, "E0 freeze sampling", b"E0\r") and ok

    rawlo = read_reg(ser, args, 6)
    rawhi = read_reg(ser, args, 7)

    if rawlo is None or rawhi is None:
        return None

    if not ok:
        return None

    return (rawhi << 8) | rawlo


def collect_sequence(ser, args, name):
    samples = []

    print("")
    print(name)

    if not configure_lfsr_test_mode(ser, args):
        return None

    for i in range(args.samples):
        sample = capture_sample(ser, args)

        if sample is None:
            return None

        samples.append(sample)
        print(f"  sample {i + 1:02d}: 0x{sample:04X}")

    return samples


def compare_sequences(first, second):
    ok = True

    print("")
    print("Evaluation:")

    if len(first) != len(second):
        print("FAIL: sequence lengths differ")
        return False

    for i, first_sample in enumerate(first):
        second_sample = second[i]

        if first_sample != second_sample:
            print(f"FAIL: mismatch at sample {i + 1}")
            print(f"  First:  0x{first_sample:04X}")
            print(f"  Second: 0x{second_sample:04X}")
            ok = False

    if ok:
        print("PASS: LFSR sequence is reproducible")
    else:
        print("FAIL: LFSR sequence is not reproducible")

    return ok


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", required=True)
    parser.add_argument("--baud", type=int, default=115200)
    parser.add_argument("--timeout", type=float, default=2.0)
    parser.add_argument("--idle-time", type=float, default=0.05)
    parser.add_argument("--samples", type=int, default=8)
    args = parser.parse_args()

    ser = serial.Serial(args.port, args.baud, timeout=0.01)

    try:
        ser.reset_input_buffer()
        ser.reset_output_buffer()

        time.sleep(0.1)

        first = collect_sequence(ser, args, "First LFSR sequence")
        second = collect_sequence(ser, args, "Second LFSR sequence")

        if first is None or second is None:
            print("")
            print("FAIL")
            return 1

        if compare_sequences(first, second):
            print("")
            print("PASS")
            return 0

        print("")
        print("FAIL")
        return 1

    finally:
        ser.close()


if __name__ == "__main__":
    sys.exit(main())