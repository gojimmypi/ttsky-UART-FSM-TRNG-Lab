#!/bin/bash
#
# Copyright (c) 2026 gojimmypi
# SPDX-License-Identifier: Apache-2.0
#
# file: wsl_x_init.sh
#
# Initialize XWindows from gygwin on Windows for GTKWave from WSL
#

set -euo pipefail

echo "**************************************************************************"
echo "**  Begin ${BASH_SOURCE[0]} from ${PWD}"
echo "**************************************************************************"

if [ -z "${WSL_DISTRO_NAME:-}" ]; then
    echo "Not WSL; no Cygwin/X setup needed."
    exit 0
fi

export DISPLAY=127.0.0.1:0.0


echo "Using DISPLAY=${DISPLAY:-<unset>}"

cmd.exe /c start "" "C:\cygwin64\bin\mintty.exe" \
    -i /Cygwin-Terminal.ico \
    -e /usr/bin/bash -lc "startxwin -- -listen tcp -ac"


echo "waiting..."

sleep 5

echo "Checking for X-Windows with xclock..."

xclock -update 1 -geometry 300x300+100+100 >/tmp/xclock.log 2>&1 &
     
xclock_pid=$!

sleep 1

if kill -0 "$xclock_pid" 2>/dev/null; then
    echo "xclock started with PID $xclock_pid"
    echo "If no window is visible, check the Windows taskbar/tray or try xeyes."
else
    cat /tmp/xclock.log
    echo "********************************************************************"
    echo "xclock failed to start."
    if [ -n "${WSL_DISTRO_NAME:-}" ]; then
        echo "WSL Detected!"
        echo "Did you run \"startxwin -- -listen tcp -ac\" from a cygwin prompt?"
    fi
fi
