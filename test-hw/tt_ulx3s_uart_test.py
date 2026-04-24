import argparse
import re
import sys
import time

import serial


EXPECTED_VERSION_PREFIX = b"Version "
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


def expect_contains(name, actual, expected):
    if expected not in actual:
        print(f"FAIL: {name}")
        print(f"  Expected to contain: {expected!r}")
        print(f"  Actual:              {actual!r}")
        return False

    print(f"PASS: {name}")
    return True


def expect_read(name, actual, reg_num, expected_value=None):
    expected_prefix = f"R{reg_num}=".encode("ascii")

    if not actual.startswith(expected_prefix):
        print(f"FAIL: {name}")
        print(f"  Expected prefix: {expected_prefix!r}")
        print(f"  Actual:          {actual!r}")
        return False

    match = READ_RE.fullmatch(actual)

    if not match:
        print(f"FAIL: {name}")
        print(f"  Invalid read format: {actual!r}")
        return False

    value = int(match.group(2), 16)

    if expected_value is not None and value != expected_value:
        print(f"FAIL: {name}")
        print(f"  Expected value: 0x{expected_value:02X}")
        print(f"  Actual value:   0x{value:02X}")
        return False

    print(f"PASS: {name}")
    return True


def test_version_if_present(ser, args):
    response = send_command(ser, b"V\r", args)

    print(f"Version probe response: {response!r}")

    if EXPECTED_VERSION_PREFIX in response:
        print("PASS: Version command")
        return True

    print("SKIP: Version command not present in this bitstream")
    return True


def test_power_on_defaults(ser, args):
    ok = True

    ok = expect_read("R0 default reg_ctrl", send_command(ser, b"R0\r", args), 0, 0x00) and ok
    ok = expect_read("R1 default reg_src", send_command(ser, b"R1\r", args), 1, 0x00) and ok
    ok = expect_read("R2 default reg_div", send_command(ser, b"R2\r", args), 2, 0x10) and ok
    ok = expect_read("R3 default reg_mode", send_command(ser, b"R3\r", args), 3, 0x00) and ok
    ok = expect_read("R4 default reg_oscen", send_command(ser, b"R4\r", args), 4, 0x01) and ok

    return ok


def test_single_nibble_writes(ser, args):
    ok = True

    ok = expect_exact("E1 write enable", send_command(ser, b"E1\r", args), b"OK\r") and ok
    ok = expect_read("R0 after E1", send_command(ser, b"R0\r", args), 0, 0x01) and ok

    ok = expect_exact("E0 clear enable", send_command(ser, b"E0\r", args), b"OK\r") and ok
    ok = expect_read("R0 after E0", send_command(ser, b"R0\r", args), 0, 0x00) and ok

    ok = expect_exact("V1 set ctrl bit 1", send_command(ser, b"V1\r", args), b"OK\r") and ok
    ok = expect_read("R0 after V1", send_command(ser, b"R0\r", args), 0, 0x02) and ok

    ok = expect_exact("W1 set ctrl bit 2", send_command(ser, b"W1\r", args), b"OK\r") and ok
    ok = expect_read("R0 after W1", send_command(ser, b"R0\r", args), 0, 0x06) and ok

    ok = expect_exact("S3 set source", send_command(ser, b"S3\r", args), b"OK\r") and ok
    ok = expect_read("R1 after S3", send_command(ser, b"R1\r", args), 1, 0x03) and ok

    ok = expect_exact("S0 clear source", send_command(ser, b"S0\r", args), b"OK\r") and ok
    ok = expect_read("R1 after S0", send_command(ser, b"R1\r", args), 1, 0x00) and ok

    return ok


def test_two_nibble_writes(ser, args):
    ok = True

    ok = expect_exact("D2A write divider", send_command(ser, b"D2A\r", args), b"OK\r") and ok
    ok = expect_read("R2 after D2A", send_command(ser, b"R2\r", args), 2, 0x2A) and ok

    ok = expect_exact("M5C write mode", send_command(ser, b"M5C\r", args), b"OK\r") and ok
    ok = expect_read("R3 after M5C", send_command(ser, b"R3\r", args), 3, 0x5C) and ok

    ok = expect_exact("O0F write oscillator enable", send_command(ser, b"O0F\r", args), b"OK\r") and ok
    ok = expect_read("R4 after O0F", send_command(ser, b"R4\r", args), 4, 0x0F) and ok

    return ok


def test_read_only_registers_format(ser, args):
    ok = True

    ok = expect_read("R5 status format", send_command(ser, b"R5\r", args), 5) and ok
    ok = expect_read("R6 rawlo format", send_command(ser, b"R6\r", args), 6) and ok
    ok = expect_read("R7 rawhi format", send_command(ser, b"R7\r", args), 7) and ok

    return ok


def test_crlf_handling(ser, args):
    ok = True

    ok = expect_exact("CRLF write accepted", send_command(ser, b"E1\r\n", args), b"OK\r") and ok
    ok = expect_read("CRLF readback", send_command(ser, b"R0\r\n", args), 0, 0x07) and ok

    return ok


def test_error_cases(ser, args):
    ok = True

    ok = expect_exact("Unknown command", send_command(ser, b"?\r", args), b"?\r") and ok
    ok = expect_exact("Bad hex digit", send_command(ser, b"EG\r", args), b"?\r") and ok
    ok = expect_exact("Bad read register", send_command(ser, b"R8\r", args), b"?\r") and ok
    ok = expect_exact("Missing second digit", send_command(ser, b"D1\r", args), b"?\r") and ok
    ok = expect_exact("Unexpected extra byte", send_command(ser, b"E10\r", args), b"?\r") and ok

    return ok


def test_repeated_reads(ser, args):
    ok = True

    for i in range(args.repeat):
        name = f"Repeated R2 read {i + 1}"
        ok = expect_read(name, send_command(ser, b"R2\r", args), 2, 0x2A) and ok

    return ok


def run_tests(ser, args):
    tests = [
        ("version_if_present", test_version_if_present),
        ("power_on_defaults", test_power_on_defaults),
        ("single_nibble_writes", test_single_nibble_writes),
        ("two_nibble_writes", test_two_nibble_writes),
        ("read_only_registers_format", test_read_only_registers_format),
        ("crlf_handling", test_crlf_handling),
        ("error_cases", test_error_cases),
        ("repeated_reads", test_repeated_reads),
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
    parser.add_argument("--port", required=True)
    parser.add_argument("--baud", type=int, default=115200)
    parser.add_argument("--timeout", type=float, default=2.0)
    parser.add_argument("--idle-time", type=float, default=0.05)
    parser.add_argument("--repeat", type=int, default=5)
    parser.add_argument("--stop-on-fail", action="store_true")

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