#!/bin/bash
#
# Copyright (c) 2026 gojimmypi
# SPDX-License-Identifier: Apache-2.0
#
# file: ice40/project_reset.sh
#

set -euo pipefail

# TT_PORT=/dev/ttyS6
BAUD=115200

if [ -z "${TT_PORT:-}" ]; then
    echo  "info: no TT_PORT found" >&2
    exit 1
else
    echo "TT_PORT:     ${TT_PORT}"
fi

if [ -z "${TT_TOP_NAME:-}" ]; then
    echo  "info: no TT_TOP_NAME found" >&2
    exit 1
else
    echo "TT_TOP_NAME: ${TT_TOP_NAME}"
fi

#    port        baud   8 bits, 1 stop, no parity, no flow control, no RTS/CTS, raw mode, no echo, min 0 chars, timeout 5 
stty -F "$TT_PORT" "$BAUD"  cs8   -cstopb  -parenb    -ixon -ixoff     -crtscts    raw      -echo min 0 time 5

exec 3<>"$TT_PORT"

send() {
    local s="$1"
    printf '>>> %s\n' "$s"
    printf '%s\r\n' "$s" >&3
    sleep 1
    timeout 1 cat <&3 || true
    printf '\n'
}

# clear any pending input
timeout 0.2 cat <&3 >/dev/null 2>&1 || true

# select project and reset
send "tt.shuttle.${TT_TOP_NAME}.enable()"
send "tt.clock_project_PWM(25000000)"
send "tt.reset_project(True)"
send "tt.reset_project(False)"

# Close file description for input / output
exec 3>&-
exec 3<&-
