#!/bin/bash

# Windows: PORT=COM8
# Linux:   PORT=/dev/ttyUSB0
# macOS:   PORT=/dev/tty.usbserial-0001
# WSL:     PORT=/dev/ttyS8

PORT=/dev/ttyS8

python tt_ulx3s_uart_test.py --port $PORT --expect-version "Version 1.2.0 4/23/2026"