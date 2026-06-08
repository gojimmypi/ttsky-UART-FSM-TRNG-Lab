#!/usr/bin/env python3
#
# Copyright (c) 2026 gojimmypi
# SPDX-License-Identifier: Apache-2.0
#
# file: ice40/project_reset.py
#

import os
import time
import serial

port = "/dev/ttyS6"

cmds = [
    "tt.shuttle.${TT_TOP_name}.enable()",
    "",
    "# Set clock to 25MHz",
    "tt.clock_project_PWM(25000000)",
    "",
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
