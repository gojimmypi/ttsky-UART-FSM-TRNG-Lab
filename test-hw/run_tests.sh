#!/bin/bash
#
# Copyright (c) 2026 gojimmypi
# SPDX-License-Identifier: Apache-2.0
#
# file: run_tests.sh
#
# usage: run_tests.sh [--with-build]

#
# Windows: PORT=COM8
# Linux:   PORT=/dev/ttyUSB0
# macOS:   PORT=/dev/tty.usbserial-0001
# WSL:     PORT=/dev/ttyS8

PORT=/dev/ttyS8

# Run shell check to ensure this a good script.
# Specify the executable shell checker you want to use:
MY_SHELLCHECK="shellcheck"

# Check if the executable is available in the PATH
if command -v "$MY_SHELLCHECK" >/dev/null 2>&1; then
    # Run your command here
    shellcheck "$0" || exit 1
else
    echo "$MY_SHELLCHECK is not installed. Please install it if changes to this script have been made."
fi

# Default: no build/flash
WITH_BUILD=0
FOUND_KNOWN_ARG=0

for arg in "$@"; do
    FOUND_KNOWN_ARG=0

    # A basic loopback that tests high level tx/rx communication
    if [ "$arg" = "--with-build" ]; then
        FOUND_KNOWN_ARG=1
        WITH_BUILD=1
        echo "Enabling build/flash mode"
    fi

    #  
    if [ "$arg" = "--ignore-combinational-warning" ]; then
        FOUND_KNOWN_ARG=1
        BUILD_ARGS="$BUILD_ARGS $arg"
        echo "Ignoring combinational network message"
    fi

    if [ "$arg" = "--no-warning-pause" ]; then
        FOUND_KNOWN_ARG=1
        BUILD_ARGS="$BUILD_ARGS $arg"
        echo "Will not pause for warnings"
    fi

    if [ "$FOUND_KNOWN_ARG" -eq 0 ]; then
        echo ""
        echo "Unknown argument: $arg"
        echo ""
        echo "Usage: $0 [--loopback] [--deep-loopback]"
        echo "          [--ignore-combinational-warning] [--no-warning-pause]"
        echo ""
        echo "  --loopback: Enable basic loopback mode for build"
        echo "  --deep-loopback: Enable deeper loopback mode for build"
        echo "  --ignore-combinational-warning: Ignore ABC combinational network warning (not recommended)"
        echo "  --no-warning-pause: Do not pause for warnings"
        exit 1
    fi 
done

if [ "$WITH_BUILD" -eq 1 ]; then
    BUILD_ARGS_ARRAY=()

    if [ -n "${BUILD_ARGS:-}" ]; then
        # shellcheck disable=SC2206
        BUILD_ARGS_ARRAY=($BUILD_ARGS)
    fi
    pushd "$(dirname "$0")"                   || exit 1
    cd ../ulx3s                               || exit 1
    echo "Build..."
    ./ulx3s_build.sh "${BUILD_ARGS_ARRAY[@]}" || exit 1
    echo "Flash..."
    ./ulx3s_flash.sh                          || exit 1
    popd                                      || exit 1
fi

# usage: tt_ulx3s_uart_test.py [-h] --port PORT [--baud BAUD] [--timeout TIMEOUT] [--idle-time IDLE_TIME]
#                              [--repeat REPEAT] [--stop-on-fail]
#                              [--reset-registers]

python tt_ulx3s_uart_test.py --port $PORT                   || exit 1

python tt_ulx3s_uart_test.py --port $PORT --reset-registers || exit 1
