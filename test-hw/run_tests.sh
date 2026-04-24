#!/bin/bash

# Windows: PORT=COM8
# Linux:   PORT=/dev/ttyUSB0
# macOS:   PORT=/dev/tty.usbserial-0001
# WSL:     PORT=/dev/ttyS8

PORT=/dev/ttyS8

# usage: tt_ulx3s_uart_test.py [-h] --port PORT [--baud BAUD] [--timeout TIMEOUT] [--idle-time IDLE_TIME]
#                              [--repeat REPEAT] [--stop-on-fail]

python tt_ulx3s_uart_test.py --port $PORT  
