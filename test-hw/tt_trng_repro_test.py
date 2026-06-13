#!/usr/bin/env python3
#
# Copyright (c) 2026 gojimmypi
# SPDX-License-Identifier: Apache-2.0
#
# file: tt_trng_repro_test.py
#
# Reproducibility test for the deterministic LFSR path in trng_lab_core.
#
# This does not test physical entropy. It verifies that source S0 can be reset
# and stepped deterministically, which makes it useful for regression testing.

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


def pulse_single_step(ser, args):
    ok = True

    # Assert the deterministic single-step bit.
    ok = write_ok(ser, args, "V1 assert single step", b"V1\r") and ok

    # Release the deterministic single-step bit.
    # The RTL detects the rising edge, so this prepares the next step.
    ok = write_ok(ser, args, "V0 release single step", b"V0\r") and ok

    return ok


def configure_lfsr_test_mode(ser, args):
    ok = True

    # Disable free-running sampling before changing configuration.
    ok = write_ok(ser, args, "E0 disable", b"E0\r") and ok

    # Clear single-step state before asserting reset.
    ok = write_ok(ser, args, "V0 clear single step", b"V0\r") and ok

    # Pulse TRNG internal reset through reg_ctrl[2].
    ok = write_ok(ser, args, "W1 assert TRNG reset", b"W1\r") and ok
    ok = write_ok(ser, args, "W0 release TRNG reset", b"W0\r") and ok

    # Select source 0:
    # SRC_LFSR deterministic test source.
    ok = write_ok(ser, args, "S0 select LFSR", b"S0\r") and ok

    # Disable all ring oscillators.
    # This keeps the test purely digital and deterministic.
    ok = write_ok(ser, args, "O00 disable oscillators", b"O00\r") and ok

    # Use fast divider for consistency with other TRNG tests.
    # The divider is not used by single-step capture.
    ok = write_ok(ser, args, "D01 set divider", b"D01\r") and ok

    return ok


def capture_sample(ser, args):
    ok = True

    # Keep free-running sampling disabled.
    ok = write_ok(ser, args, "E0 disable sampling", b"E0\r") and ok

    # Build one reported sample from several deterministic one-bit captures.
    # With the default of 16 steps, R6/R7 contains a full 16-bit sample_shift
    # value instead of the early 0001, 0003, 0007 fill pattern.
    for _ in range(args.bits_per_sample):
        ok = pulse_single_step(ser, args) and ok

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


def evaluate_sequence(samples):
    unique_count = len(set(samples))
    zero_count = samples.count(0x0000)
    ones_count = samples.count(0xFFFF)

    bit_ones = 0
    total_bits = len(samples) * 16

    for sample in samples:
        bit_ones += sample.bit_count()

    bit_ratio = bit_ones / total_bits

    print("")
    print("Sequence quality check:")
    print(f"  Samples:      {len(samples)}")
    print(f"  Unique:       {unique_count}")
    print(f"  Zero samples: {zero_count}")
    print(f"  0xFFFF count: {ones_count}")
    print(f"  One bits:     {bit_ones}/{total_bits}")
    print(f"  One ratio:    {bit_ratio:.3f}")

    if unique_count < 2:
        print("FAIL: deterministic sequence is stuck")
        return False

    if zero_count == len(samples):
        print("FAIL: deterministic sequence is all zero")
        return False

    if ones_count == len(samples):
        print("FAIL: deterministic sequence is all 0xFFFF")
        return False

    print("PASS: deterministic sequence is not stuck")
    return True


def compare_sequences(first, second):
    ok = True

    print("")
    print("Reproducibility evaluation:")

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
    parser.add_argument("--bits-per-sample", type=int, default=16)
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

        ok = True
        ok = compare_sequences(first, second) and ok
        ok = evaluate_sequence(first) and ok

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
