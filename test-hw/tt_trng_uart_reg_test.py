#!/usr/bin/env python3
#
# Copyright (c) 2026 gojimmypi
# SPDX-License-Identifier: Apache-2.0
#
# file: tt_trng_uart_reg_test.py
#

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


def run_command_list(ser, args, title, commands):
    print("")
    print(title)
    print("=" * len(title))

    for cmd in commands:
        send_cmd(ser, cmd, args)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", required=True)
    parser.add_argument("--baud", type=int, default=115200)
    parser.add_argument("--timeout", type=float, default=2.0)
    parser.add_argument("--idle-time", type=float, default=0.05)
    args = parser.parse_args()

    lfsr_frozen_sample_test = [

        # Disable TRNG updates while configuring registers.
        "E0",

        # Select source 0:
        # SRC_LFSR deterministic test mode.
        "S0",

        # Set fast sample divider.
        # Lower values update samples more quickly.
        "D01",

        # Disable all ring oscillators.
        # Pure deterministic LFSR mode.
        "O00",

        # Enable TRNG sampling.
        "E1",

        # Freeze the sample register contents so
        # R6/R7 belong to the same captured sample.
        "E0",

        # Read low byte of captured sample.
        "R6",

        # Read high byte of captured sample.
        "R7",

        # Re-enable sampling to generate a new sample.
        "E1",

        # Freeze again before reading.
        "E0",

        # Read next sample low byte.
        "R6",

        # Read next sample high byte.
        "R7",

        # Slow down sampling rate substantially.
        "D40",

        # Enable sampling again using slower divider.
        "E1",

        # Freeze captured sample.
        "E0",

        # Read low byte of slower-updating sample.
        "R6",

        # Read high byte of slower-updating sample.
        "R7",
    ]

    source_select_fallback_test = [

        # Disable TRNG updates before changing source select.
        "E0",

        # Select source 1:
        # SRC_RO0 single oscillator path.
        "S1",

        # Enable only oscillator 0.
        "O01",

        # Use fast sampling for this source-select test.
        "D01",

        # Enable TRNG sampling.
        "E1",

        # Freeze captured sample.
        "E0",

        # Read low byte from SRC_RO0 path.
        "R6",

        # Read high byte from SRC_RO0 path.
        "R7",

        # Disable TRNG updates before changing source select.
        "E0",

        # Select source 2:
        # SRC_ROX XOR of enabled oscillator paths.
        "S2",

        # Enable all oscillator mask bits.
        "OFF",

        # Use fast sampling.
        "D01",

        # Enable TRNG sampling.
        "E1",

        # Freeze captured sample.
        "E0",

        # Read low byte from SRC_ROX path.
        "R6",

        # Read high byte from SRC_ROX path.
        "R7",

        # Disable TRNG updates before changing source select.
        "E0",

        # Select source 3:
        # SRC_MIX mixed RO/LFSR/history path.
        "S3",

        # Enable all oscillator mask bits.
        "OFF",

        # Use fast sampling.
        "D01",

        # Enable TRNG sampling.
        "E1",

        # Freeze captured sample.
        "E0",

        # Read low byte from SRC_MIX path.
        "R6",

        # Read high byte from SRC_MIX path.
        "R7",
    ]

    health_status_smoke_test = [

        # Stop sampling before clearing health state.
        "E0",

        # Assert and release the TRNG reset bit. This also clears
        # sticky health-monitor state in TRNG_HEALTH_STATUS builds.
        "W1",
        "W0",

        # Select the single-oscillator source path.
        "S1",

        # Enable oscillator 0 only.
        "O01",

        # Use fast sampling so the 64-sample health window completes quickly.
        "D01",

        # Enable sampling and then read R5 several times. R5 should progress
        # from basic enable/oscillator status to health_valid/activity_seen.
        "E1",
        "R5",
        "R5",
        "R5",

        # Stop sampling and read R5 once more for final manual inspection.
        "E0",
        "R5",
    ]

    ser = serial.Serial(args.port, args.baud, timeout=0.01)

    try:
        ser.reset_input_buffer()
        ser.reset_output_buffer()

        time.sleep(0.1)

        run_command_list(
            ser,
            args,
            "Test 1: LFSR frozen sample test",
            lfsr_frozen_sample_test,
        )

        run_command_list(
            ser,
            args,
            "Test 2: Source-select fallback test",
            source_select_fallback_test,
        )

        run_command_list(
            ser,
            args,
            "Test 3: Health status smoke test",
            health_status_smoke_test,
        )

    finally:
        ser.close()


if __name__ == "__main__":
    main()