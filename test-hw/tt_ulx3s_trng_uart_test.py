#!/usr/bin/env python3
#
# Copyright (c) 2026 gojimmypi
# SPDX-License-Identifier: Apache-2.0
#
# file: tt_ulx3s_trng_uart_test.py

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


def expect_exact(name, actual, expected):
    if actual != expected:
        print(f"FAIL: {name}")
        print(f"  Expected: {expected!r}")
        print(f"  Actual:   {actual!r}")
        return False

    print(f"PASS: {name}")
    return True


def read_reg(ser, args, reg_num):
    command = f"R{reg_num}\r".encode("ascii")
    response = send_command(ser, command, args)

    match = READ_RE.fullmatch(response)

    if not match:
        print(f"FAIL: R{reg_num} read")
        print(f"  Actual: {response!r}")
        return None

    return int(match.group(2), 16)


def write_ok(ser, args, name, command):
    response = send_command(ser, command, args)
    return expect_exact(name, response, b"OK\r")


def capture_sample(ser, args):
    ok = True

    # Enable TRNG sampling long enough to update the sample register.
    ok = write_ok(ser, args, "Enable sampling", b"E1\r") and ok

    # Freeze R6/R7 so both bytes belong to the same captured sample.
    ok = write_ok(ser, args, "Freeze sampling", b"E0\r") and ok

    rawlo = read_reg(ser, args, 6)
    rawhi = read_reg(ser, args, 7)

    if rawlo is None or rawhi is None:
        return None

    if not ok:
        return None

    return (rawhi << 8) | rawlo


def configure_source(ser, args, source_cmd, osc_cmd, div_cmd):
    ok = True

    # Disable updates before changing TRNG configuration.
    ok = write_ok(ser, args, "Configure E0", b"E0\r") and ok

    # Select TRNG source:
    # S0 = LFSR
    # S1 = RO0 path
    # S2 = RO XOR path
    # S3 = mixed path
    ok = write_ok(ser, args, "Configure source", source_cmd) and ok

    # Set oscillator enable mask.
    ok = write_ok(ser, args, "Configure oscillator mask", osc_cmd) and ok

    # Set sample divider.
    ok = write_ok(ser, args, "Configure divider", div_cmd) and ok

    return ok


def evaluate_samples(name, samples):
    ok = True

    unique_count = len(set(samples))
    zero_count = samples.count(0x0000)
    ones_count = samples.count(0xFFFF)

    bit_ones = 0
    total_bits = len(samples) * 16

    for sample in samples:
        bit_ones += sample.bit_count()

    bit_ratio = bit_ones / total_bits

    print("")
    print(f"Evaluation: {name}")
    print(f"  Samples:      {len(samples)}")
    print(f"  Unique:       {unique_count}")
    print(f"  Zero samples: {zero_count}")
    print(f"  0xFFFF count: {ones_count}")
    print(f"  One bits:     {bit_ones}/{total_bits}")
    print(f"  One ratio:    {bit_ratio:.3f}")

    if unique_count < 2:
        print("FAIL: sample output is stuck")
        ok = False
    else:
        print("PASS: sample output changes")

    if zero_count == len(samples):
        print("FAIL: all samples are zero")
        ok = False

    if ones_count == len(samples):
        print("FAIL: all samples are 0xFFFF")
        ok = False

    if bit_ratio < 0.20 or bit_ratio > 0.80:
        print("WARN: bit balance is suspicious for this small sample set")
    else:
        print("PASS: bit balance is reasonable for this small sample set")

    return ok


def collect_samples(ser, args, name, source_cmd, osc_cmd, div_cmd):
    samples = []

    print("")
    print(f"Running: {name}")

    if not configure_source(ser, args, source_cmd, osc_cmd, div_cmd):
        return False

    for i in range(args.samples):
        sample = capture_sample(ser, args)

        if sample is None:
            return False

        samples.append(sample)
        print(f"  sample {i + 1:02d}: 0x{sample:04X}")

    return evaluate_samples(name, samples)


def test_lfsr_frozen_samples(ser, args):
    return collect_samples(
        ser,
        args,
        "TRNG S0 LFSR frozen samples",
        b"S0\r",
        b"O00\r",
        b"D01\r",
    )


def test_source_select_paths(ser, args):
    ok = True

    ok = collect_samples(
        ser,
        args,
        "TRNG S1 RO0/fallback path",
        b"S1\r",
        b"O01\r",
        b"D01\r",
    ) and ok

    ok = collect_samples(
        ser,
        args,
        "TRNG S2 ROX/fallback path",
        b"S2\r",
        b"OFF\r",
        b"D01\r",
    ) and ok

    ok = collect_samples(
        ser,
        args,
        "TRNG S3 MIX/fallback path",
        b"S3\r",
        b"OFF\r",
        b"D01\r",
    ) and ok

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

        ok = True
        ok = test_lfsr_frozen_samples(ser, args) and ok
        ok = test_source_select_paths(ser, args) and ok

        print("")

        if ok:
            print("PASS")
            return 0

        print("FAIL")
        return 1

    finally:
        ser.close()


if __name__ == "__main__":
    sys.exit(main())