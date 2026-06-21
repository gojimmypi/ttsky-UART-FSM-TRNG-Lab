#!/usr/bin/env python3
#
# Copyright (c) 2026 gojimmypi
# SPDX-License-Identifier: Apache-2.0
#
# file: ice40/project_reset.py
#
# Do not move this file. Referenced by TT 4337 Documentation https://app.tinytapeout.com/projects/4337

import os
import sys
import time
import serial

# Windows: PORT=COM5
# WSL:     PORT=/dev/ttyS5
# Linux:   PORT=/dev/ttyUSB5 or /dev/ttyACM5
# macOS:   PORT=/dev/tty.usbserial-0005

MY_PORT = os.environ.get("MY_PORT") or "/dev/ttyS6"

port = MY_PORT

TT_TOP_NAME = os.environ.get("TT_TOP_NAME") or ""

if not TT_TOP_NAME:
    print("ERROR: TT_TOP_NAME is not set, do you need to run `source env_ice40.sh` ?")
    sys.exit(1)

cmds = [
    f"tt.shuttle.{TT_TOP_NAME}.enable()",
    "# Set clock to 25MHz",
    "tt.clock_project_PWM(25000000)",
    "tt.reset_project(True)",
    "tt.reset_project(False)",
]

with serial.Serial(port, 115200, timeout=0.2) as ser:
    time.sleep(0.5)
    ser.reset_input_buffer()

    for cmd in cmds:
        if cmd.startswith("#"):
            print(cmd)
            continue

        line = cmd + "\r\n"
        print(f">>> {cmd}")
        ser.write(line.encode("utf-8"))
        ser.flush()

        time.sleep(1.0)

        out = ser.read(4096)
        if out:
            print(out.decode("utf-8", errors="replace"), end="")
