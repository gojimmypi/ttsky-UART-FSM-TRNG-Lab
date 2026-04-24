import argparse
import sys
import time

import serial


EXPECTED_VERSION_PREFIX = b"Version "


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


def send_command(ser, command, idle_time, max_time):
    ser.reset_input_buffer()

    ser.write(command)
    ser.flush()

    return read_until_idle(ser, idle_time, max_time)


def check_contains(name, response, expected):
    if expected not in response:
        print(f"FAIL: {name}")
        print(f"  Expected to contain: {expected!r}")
        print(f"  Actual response:      {response!r}")
        return False

    print(f"PASS: {name}")
    return True


def check_uart_still_alive(ser, idle_time, max_time):
    response = send_command(ser, b"V\r", idle_time, max_time)

    return check_contains("UART still alive after previous command",
                          response,
                          EXPECTED_VERSION_PREFIX)


def test_version(ser, args):
    response = send_command(ser, b"V\r", args.idle_time, args.timeout)

    print(f"Version response: {response!r}")

    if not check_contains("Version command", response, EXPECTED_VERSION_PREFIX):
        return False

    if args.expect_version is not None:
        expected = args.expect_version.encode("ascii")

        if expected not in response:
            print("FAIL: Exact version string")
            print(f"  Expected to contain: {expected!r}")
            print(f"  Actual response:      {response!r}")
            return False

        print("PASS: Exact version string")

    return True


def test_empty_command(ser, args):
    response = send_command(ser, b"\r", args.idle_time, args.timeout)

    print(f"Empty command response: {response!r}")

    return check_uart_still_alive(ser, args.idle_time, args.timeout)


def test_unknown_command(ser, args):
    response = send_command(ser, b"?\r", args.idle_time, args.timeout)

    print(f"Unknown command response: {response!r}")

    return check_uart_still_alive(ser, args.idle_time, args.timeout)


def test_repeated_version(ser, args):
    ok = True

    for i in range(args.repeat):
        response = send_command(ser, b"V\r", args.idle_time, args.timeout)

        name = f"Repeated version command {i + 1}"

        if not check_contains(name, response, EXPECTED_VERSION_PREFIX):
            ok = False
            break

    return ok


def run_tests(ser, args):
    tests = [
        ("version", test_version),
        ("empty_command", test_empty_command),
        ("unknown_command", test_unknown_command),
        ("repeated_version", test_repeated_version),
    ]

    passed = 0
    failed = 0

    for name, func in tests:
        print("")
        print(f"Running: {name}")

        if func(ser, args):
            passed += 1
        else:
            failed += 1

            if args.stop_on_fail:
                break

    print("")
    print(f"Tests passed: {passed}")
    print(f"Tests failed: {failed}")

    return failed == 0


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", required=True, help="Serial port, for example COM5 or /dev/ttyS3 or /dev/ttyUSB0")
    parser.add_argument("--baud", type=int, default=115200, help="UART baud rate")
    parser.add_argument("--timeout", type=float, default=2.0, help="Maximum read time in seconds")
    parser.add_argument("--idle-time", type=float, default=0.05, help="End response after this much idle time")
    parser.add_argument("--repeat", type=int, default=5, help="Repeat count for repeated-command tests")
    parser.add_argument("--expect-version", help="Exact version text expected, for example: Version 1.2.1 4/24/2026")
    parser.add_argument("--stop-on-fail", action="store_true", help="Stop after first failed test")

    args = parser.parse_args()

    ser = serial.Serial(args.port, args.baud, timeout=0.01)

    try:
        ser.reset_input_buffer()
        ser.reset_output_buffer()

        time.sleep(0.1)

        if run_tests(ser, args):
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