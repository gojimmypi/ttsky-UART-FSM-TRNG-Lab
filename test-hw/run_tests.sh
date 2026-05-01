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

PORT=/dev/ttyS11

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
IS_LOOPBACK=0
WITH_BUILD=0
FOUND_KNOWN_ARG=0
EXPECT_PORT_VALUE=0

# ------------------------------------------------------------------------------
# Parameter processing
# ------------------------------------------------------------------------------
for arg in "$@"; do
    FOUND_KNOWN_ARG=0

    # --------------------------------------------------------------------------
    # First look at optiona that require a parameter
    # --------------------------------------------------------------------------
    # Handle value for previous --port
    if [ "$EXPECT_PORT_VALUE" -eq 1 ]; then
        PORT="$arg"
        EXPECT_PORT_VALUE=0

        FOUND_KNOWN_ARG=1
        echo "Using port: $PORT"
        continue
    fi

    if [ "$arg" = "--port" ]; then
        echo "Will use specified port instead of $PORT"
        FOUND_KNOWN_ARG=1
        if [ -z "$1" ]; then
            echo "Error: --port requires a value"
            exit 1
        fi
        EXPECT_PORT_VALUE=1
    fi

    # ----------------------------------------------------------------
    # Non-parameter options follow
    # ----------------------------------------------------------------
    # A basic loopback that tests high level tx/rx communication
    if [ "$arg" = "--loopback" ]; then
        FOUND_KNOWN_ARG=1
        IS_LOOPBACK=1
        BUILD_ARGS="$BUILD_ARGS $arg"
        echo "Enabling loopback mode for build"
    fi

    # A deeper and more complex logic loopback that tests more of the internal logic and is more likely to catch issues
    if [ "$arg" = "--deep-loopback" ]; then
        FOUND_KNOWN_ARG=1
        IS_LOOPBACK=1
        BUILD_ARGS="$BUILD_ARGS $arg"
        echo "Enabling deep loopback mode for build"
    fi

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
        echo "          [--port <port>]"
        echo ""
        echo "  --loopback: Enable basic loopback mode for build"
        echo "  --deep-loopback: Enable deeper loopback mode for build"
        echo "  --ignore-combinational-warning: Ignore ABC combinational network warning (not recommended)"
        echo "  --no-warning-pause: Do not pause for warnings"
        exit 1
    fi 
done

if [ "$EXPECT_PORT_VALUE" -eq 1 ]; then
    echo "Error: --port requires a value"
    exit 1
fi


# ------------------------------------------------------------------------------
# Optional build
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Run tests
# ------------------------------------------------------------------------------
if [ "$IS_LOOPBACK" -eq 1 ]; then
    echo ""
    echo "Begin loopback tests..."
    # loopback_test.py [-h] [-b BAUD] [-t TIMEOUT] [-m MESSAGE] [-n REPEAT] port

    # The safest test to start (default write_with_delay when --bulk not specified)
    echo "Test default params"
    python ./loopback_test.py --port "$PORT" -b 115200                  || exit 1
    printf "Test default params - complete.\n\n"

    echo "Test non-bulk mode, delay = 0.005"
    python ./loopback_test.py --port "$PORT" -b 115200 --tx-delay 0.005 || exit 1
    printf "Test non-bulk mode, delay = 0.005 - complete.\n\n"

    echo "Test non-bulk mode, delay = 0.001"
    python ./loopback_test.py --port "$PORT" -b 115200 --tx-delay 0.001 || exit 1
    printf "Test non-bulk mode, delay = 0.001 - complete.\n\n"

    echo "Test non-bulk mode, delay = 0.000"
    python ./loopback_test.py --port "$PORT" -b 115200 --tx-delay 0.000 || exit 1
    printf "Test non-bulk mode, delay = 0.000 - complete.\n\n"

    echo "Test bulk mode most challenging"
    python ./loopback_test.py --port "$PORT" -b 115200 --bulk           || exit 1
    printf "Test bulk mode most challenging - complete.\n\n"
else
    # usage: tt_ulx3s_uart_test.py [-h] --port PORT [--baud BAUD] [--timeout TIMEOUT] [--idle-time IDLE_TIME]
    #                              [--repeat REPEAT] [--stop-on-fail]
    #                              [--reset-registers]

    python ./tt_ulx3s_uart_test.py --port "$PORT"                   || exit 1

    python ./tt_ulx3s_uart_test.py --port "$PORT" --reset-registers || exit 1
fi