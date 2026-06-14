#!/usr/bin/env python3
#
# Copyright (c) 2026 gojimmypi
# SPDX-License-Identifier: Apache-2.0
#
# file: tt_trng_uart_test.py

import argparse
import re
import sys
import time

import serial


READ_RE = re.compile(rb"R([0-7])=([0-9A-F]{2})\r")

R5_TRNG_ENABLE = 0x01
R5_SAMPLE_TICK = 0x02
R5_ANY_OSC_EN = 0x04
R5_HEALTH_VALID = 0x08
R5_ACTIVITY_SEEN = 0x10
R5_REPETITION_FAIL = 0x20
R5_STUCK_FAIL = 0x40
R5_HEALTH_FAIL = 0x80

R5_HEALTH_MASK = (
    R5_HEALTH_VALID
    | R5_ACTIVITY_SEEN
    | R5_REPETITION_FAIL
    | R5_STUCK_FAIL
    | R5_HEALTH_FAIL
)

R5_FLAG_NAMES = (
    (R5_TRNG_ENABLE, "trng_enable"),
    (R5_SAMPLE_TICK, "sample_tick"),
    (R5_ANY_OSC_EN, "any_osc_en"),
    (R5_HEALTH_VALID, "health_valid"),
    (R5_ACTIVITY_SEEN, "activity_seen"),
    (R5_REPETITION_FAIL, "repetition_fail"),
    (R5_STUCK_FAIL, "stuck_fail"),
    (R5_HEALTH_FAIL, "health_fail"),
)


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


def read_exact(ser, length, max_time):
    data = bytearray()
    start_time = time.monotonic()

    while len(data) < length:
        chunk = ser.read(length - len(data))

        if chunk:
            data.extend(chunk)
            continue

        if (time.monotonic() - start_time) >= max_time:
            break

    return bytes(data)


def read_any_before_timeout(ser, max_time):
    start_time = time.monotonic()

    while True:
        chunk = ser.read(1)

        if chunk:
            return chunk

        if (time.monotonic() - start_time) >= max_time:
            return b""


def send_binary_command(ser, command, length, args):
    ser.reset_input_buffer()
    ser.write(command)
    ser.flush()
    return read_exact(ser, length, args.timeout)


def expect_exact(name, actual, expected):
    if actual != expected:
        print(f"FAIL: {name}")
        print(f"  Expected: {expected!r}")
        print(f"  Actual:   {actual!r}")
        return False

    print(f"PASS: {name}")
    return True


def expect_length(name, actual, expected_length):
    actual_length = len(actual)

    if actual_length != expected_length:
        print(f"FAIL: {name}")
        print(f"  Expected length: {expected_length}")
        print(f"  Actual length:   {actual_length}")
        print(f"  Actual data:     {actual!r}")
        return False

    print(f"PASS: {name}")
    return True


def expect_no_extra_byte(name, actual):
    if actual:
        print(f"FAIL: {name}")
        print(f"  Extra byte: {actual!r}")
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


def format_r5_status(value):
    flags = []

    for mask, name in R5_FLAG_NAMES:
        if value & mask:
            flags.append(name)

    if not flags:
        return f"0x{value:02X} (no flags set)"

    return f"0x{value:02X} (" + ", ".join(flags) + ")"


def check_status_bits(name, value, set_mask=0, clear_mask=0):
    ok = True

    if (value & set_mask) != set_mask:
        print(f"FAIL: {name}")
        print(f"  Missing set bits: 0x{set_mask & ~value:02X}")
        print(f"  Status:           {format_r5_status(value)}")
        ok = False

    if value & clear_mask:
        print(f"FAIL: {name}")
        print(f"  Unexpected bits:  0x{value & clear_mask:02X}")
        print(f"  Status:           {format_r5_status(value)}")
        ok = False

    if ok:
        print(f"PASS: {name}: {format_r5_status(value)}")

    return ok


def wait_for_status_bits(ser, args, name, set_mask=0, clear_mask=0):
    last_status = None

    for _ in range(args.health_poll_attempts):
        status = read_reg(ser, args, 5)

        if status is None:
            return None

        last_status = status

        if (status & set_mask) == set_mask and (status & clear_mask) == 0:
            print(f"PASS: {name}: {format_r5_status(status)}")
            return status

        time.sleep(args.health_poll_delay)

    print(f"FAIL: {name}")

    if last_status is None:
        print("  No R5 status value was read")
    else:
        print(f"  Last status: {format_r5_status(last_status)}")
        if (last_status & set_mask) != set_mask:
            print(f"  Missing set bits: 0x{set_mask & ~last_status:02X}")
        if last_status & clear_mask:
            print(f"  Unexpected bits:  0x{last_status & clear_mask:02X}")

    return None


def clear_trng_health_state(ser, args):
    ok = True

    # E0 stops sampling. W1 asserts the TRNG reset/health clear path.
    # W0 releases it again before the health test starts.
    ok = write_ok(ser, args, "Health clear E0", b"E0\r") and ok
    ok = write_ok(ser, args, "Health clear W1", b"W1\r") and ok
    ok = write_ok(ser, args, "Health clear W0", b"W0\r") and ok

    return ok


def reset_config_registers(ser, args):
    ok = True

    ok = write_ok(ser, args, "Reset E0", b"E0\r") and ok
    ok = write_ok(ser, args, "Reset V0", b"V0\r") and ok
    ok = write_ok(ser, args, "Reset W0", b"W0\r") and ok
    ok = write_ok(ser, args, "Reset S0", b"S0\r") and ok
    ok = write_ok(ser, args, "Reset D10", b"D10\r") and ok
    ok = write_ok(ser, args, "Reset M00", b"M00\r") and ok
    ok = write_ok(ser, args, "Reset O01", b"O01\r") and ok

    return ok


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


def test_health_status_reset_clear(ser, args):
    ok = True

    print("")
    print("Running: TRNG health status reset/clear")

    ok = reset_config_registers(ser, args) and ok

    # Disable oscillators before clearing so the post-clear status is stable.
    ok = write_ok(ser, args, "Health reset O00 oscillators", b"O00\r") and ok
    ok = clear_trng_health_state(ser, args) and ok

    status = read_reg(ser, args, 5)

    if status is None:
        return False

    ok = check_status_bits(
        "R5 health bits clear after W reset",
        status,
        clear_mask=(R5_TRNG_ENABLE | R5_ANY_OSC_EN | R5_HEALTH_MASK),
    ) and ok

    return ok


def test_health_status_active_oscillator(ser, args):
    ok = True

    print("")
    print("Running: TRNG health status active oscillator")

    ok = reset_config_registers(ser, args) and ok
    ok = clear_trng_health_state(ser, args) and ok

    # Use one enabled oscillator so rox_sample_sync should follow real RO activity.
    ok = configure_source(ser, args, b"S1\r", b"O01\r", b"D01\r") and ok
    ok = write_ok(ser, args, "Health E1 enable", b"E1\r") and ok

    status = wait_for_status_bits(
        ser,
        args,
        "R5 active oscillator health",
        set_mask=(
            R5_TRNG_ENABLE
            | R5_ANY_OSC_EN
            | R5_HEALTH_VALID
            | R5_ACTIVITY_SEEN
        ),
        clear_mask=(R5_STUCK_FAIL | R5_HEALTH_FAIL),
    )

    if status is None:
        ok = False
    else:
        ok = check_status_bits(
            "R5 active oscillator failure bits",
            status,
            clear_mask=(R5_STUCK_FAIL | R5_HEALTH_FAIL),
        ) and ok

    ok = write_ok(ser, args, "Health cleanup E0", b"E0\r") and ok

    return ok


def test_binary_stream_exact_length(ser, args):
    ok = True

    print("")
    print("Running: TRNG binary stream exact length")

    # Start from known register defaults before entering binary-stream mode.
    ok = reset_config_registers(ser, args) and ok

    # Disable updates before changing TRNG stream configuration.
    ok = write_ok(ser, args, "Binary stream reset E0", b"E0\r") and ok

    # Configure the same path that exposed the prior stream bug class.
    ok = write_ok(ser, args, "Binary stream S3 mixed source", b"S3\r") and ok
    ok = write_ok(ser, args, "Binary stream OFF oscillators", b"OFF\r") and ok
    ok = write_ok(ser, args, "Binary stream D0F divider", b"D0F\r") and ok
    ok = write_ok(ser, args, "Binary stream E1 enable", b"E1\r") and ok

    data = send_binary_command(ser, b"C10\r", 16, args)
    ok = expect_length("C10 returns exactly 16 bytes", data, 16) and ok

    extra = read_any_before_timeout(ser, args.extra_timeout)
    ok = expect_no_extra_byte("C10 has no extra byte", extra) and ok

    ok = write_ok(ser, args, "Binary stream cleanup E0", b"E0\r") and ok

    reg_ctrl = read_reg(ser, args, 0)

    if reg_ctrl is None:
        ok = False
    elif reg_ctrl != 0x00:
        print("FAIL: R0 after binary stream cleanup")
        print("  Expected: 0x00")
        print(f"  Actual:   0x{reg_ctrl:02X}")
        ok = False
    else:
        print("PASS: R0 after binary stream cleanup")

    return ok


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
    parser.add_argument("--extra-timeout", type=float, default=0.25)
    parser.add_argument("--samples", type=int, default=8)
    parser.add_argument("--skip-health-status", action="store_true")
    parser.add_argument("--health-poll-attempts", type=int, default=20)
    parser.add_argument("--health-poll-delay", type=float, default=0.005)
    args = parser.parse_args()

    ser = serial.Serial(args.port, args.baud, timeout=0.01)

    try:
        ser.reset_input_buffer()
        ser.reset_output_buffer()

        time.sleep(0.1)

        ok = True

        if not args.skip_health_status:
            ok = test_health_status_reset_clear(ser, args) and ok
            ok = test_health_status_active_oscillator(ser, args) and ok

        ok = test_binary_stream_exact_length(ser, args) and ok
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