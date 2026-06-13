#!/usr/bin/env python3
#
# Copyright (c) 2026 gojimmypi
# SPDX-License-Identifier: Apache-2.0
#
# file: test-hw/capture_trng_raw_uart.py

import argparse
import os
import sys
import time

import serial


DEFAULT_BAUD = 115200
FAST_BAUD = 921600


def write_cmd(ser, cmd):
    ser.write(cmd)
    ser.flush()


def read_exact(ser, count, timeout_retries):
    data = bytearray()
    empty_reads = 0

    while len(data) < count:
        chunk = ser.read(count - len(data))

        if not chunk:
            if empty_reads >= timeout_retries:
                raise TimeoutError(
                    f"timeout after {len(data)} of {count} bytes "
                    f"after {empty_reads + 1} read timeouts"
                )

            empty_reads += 1
            continue

        empty_reads = 0
        data.extend(chunk)

    return bytes(data)


def read_cr_response(ser):
    return ser.read_until(b"\r")


def send_ascii_cmd(ser, cmd, expected=None):
    write_cmd(ser, cmd)
    response = read_cr_response(ser)

    if expected is not None and response != expected:
        raise RuntimeError(
            f"unexpected response to {cmd!r}: expected {expected!r}, got {response!r}"
        )

    return response


def send_baud_cmd(ser, baud_sel):
    cmd = f"U{baud_sel:X}\r".encode("ascii")

    ser.reset_input_buffer()
    write_cmd(ser, cmd)
    response = read_cr_response(ser)

    # The UART baud command can change baud before the host sees the final CR.
    # Treat any response beginning with OK as success; extra bytes may be the
    # trailing CR or stale binary-stream data seen at the wrong baud.
    if not response.startswith(b"OK"):
        raise RuntimeError(
            f"unexpected response to {cmd!r}: expected response starting with b'OK', got {response!r}"
        )

    return response


def set_uart_baud(ser, baud_sel, new_baud):
    response = send_baud_cmd(ser, baud_sel)

    ser.baudrate = new_baud
    ser.reset_input_buffer()
    ser.reset_output_buffer()
    time.sleep(0.1)

    return response


def configure_trng(ser):
    # Recommended raw capture setup:
    # E0: freeze while configuring
    # S3: mixed source
    # OFF: enable all oscillator bits
    # D01: fast sample divider
    # E1: enable free-running sampling
    for cmd in (b"E0\r", b"S3\r", b"OFF\r", b"D0F\r", b"E1\r"):
        send_ascii_cmd(ser, cmd, b"OK\r")

    # for cmd in (b"E0\r", b"S3\r", b"OFF\r", b"D1F\r", b"E1\r"):
    #    send_ascii_cmd(ser, cmd, b"OK\r")

def capture_binary_stream(ser, byte_count, out_path, conditioned, timeout_retries):
    remaining = byte_count
    stream_cmd = "C" if conditioned else "B"

    with open(out_path, "wb") as f:
        while remaining:
            chunk_len = min(remaining, 255)
            cmd = f"{stream_cmd}{chunk_len:02X}\r".encode("ascii")

            write_cmd(ser, cmd)

            data = read_exact(ser, chunk_len, timeout_retries)
            f.write(data)

            remaining -= chunk_len


def remove_file_quietly(path):
    try:
        os.remove(path)
    except FileNotFoundError:
        pass


def capture_with_retries(ser, args):
    out_tmp = f"{args.out}.tmp"
    fast_baud_active = False

    for attempt in range(1, args.capture_retries + 1):
        if attempt > 1:
            print(
                f"retrying capture attempt {attempt} of {args.capture_retries}",
                file=sys.stderr,
            )

        ser.reset_input_buffer()
        ser.reset_output_buffer()

        time.sleep(0.1)

        configure_trng(ser)

        if args.fast_baud and not fast_baud_active:
            set_uart_baud(ser, 3, FAST_BAUD)
            fast_baud_active = True

        try:
            capture_binary_stream(
                ser,
                args.bytes,
                out_tmp,
                args.conditioned,
                args.read_timeout_retries,
            )
            os.replace(out_tmp, args.out)
            return fast_baud_active
        except TimeoutError as exc:
            remove_file_quietly(out_tmp)

            if attempt >= args.capture_retries:
                raise

            print(f"warning: capture attempt {attempt} failed: {exc}", file=sys.stderr)
            time.sleep(1.0)

    return fast_baud_active


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", required=True)
    parser.add_argument("--baud", type=int, default=DEFAULT_BAUD)
    parser.add_argument("--fast-baud", action="store_true",
                        help="switch to 921600 baud during binary capture using U3")
    parser.add_argument("--conditioned", action="store_true",
                        help="capture conditioned stream using Cxx instead of raw Bxx")
    parser.add_argument("--bytes", type=int, default=1024)
    parser.add_argument("--out", required=True)
    parser.add_argument("--timeout", type=float, default=2.0)
    parser.add_argument("--read-timeout-retries", type=int, default=3,
                        help="additional serial read timeouts before failing a chunk")
    parser.add_argument("--capture-retries", type=int, default=3,
                        help="retry the whole capture from byte zero after a timeout")
    args = parser.parse_args()

    if args.bytes < 1:
        print("error: --bytes must be at least 1", file=sys.stderr)
        return 1

    if args.read_timeout_retries < 0:
        print("error: --read-timeout-retries must be at least 0", file=sys.stderr)
        return 1

    if args.capture_retries < 1:
        print("error: --capture-retries must be at least 1", file=sys.stderr)
        return 1

    original_baud = args.baud
    fast_baud_active = False

    with serial.Serial(args.port, args.baud, timeout=args.timeout) as ser:
        ser.reset_input_buffer()
        ser.reset_output_buffer()

        time.sleep(0.1)

        try:
            fast_baud_active = capture_with_retries(ser, args)

        finally:
            if fast_baud_active:
                try:
                    # Send U0 at the current fast baud. The RTL replies OK at the
                    # current baud, then switches back to the default baud.
                    set_uart_baud(ser, 0, original_baud)
                except Exception as exc:
                    print(f"warning: failed to restore default UART baud: {exc}", file=sys.stderr)
                    print("warning: reset the project or reconnect at the expected baud", file=sys.stderr)

    return 0


if __name__ == "__main__":
    sys.exit(main())
