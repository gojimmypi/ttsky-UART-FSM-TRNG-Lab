#!/bin/bash
#
# Copyright (c) 2026 gojimmypi
# SPDX-License-Identifier: Apache-2.0
#
# file: run_tests.sh
#
# usage: run_tests.sh [--with-build]
#                     [--loopback]
#                     [--deep-loopback]
#                     [--pause-for-test]
#                     [--ignore-combinational-warning]
#                     [--no-warning-pause]
#                     [--ulx3s-board-version <version>]
#                     [--ulx3s-board-version=<version>]
#                     [--board-version <version>]
#                     [--board-version=<version>]
#                     [--port <port>]
#
# Options:
#
#   --with-build
#       Build and flash the ULX3S bitstream before running tests.
#
#   --loopback
#       Enable basic loopback mode for the build and run loopback tests.
#
#   --deep-loopback
#       Enable deeper internal loopback mode for the build and run loopback tests.
#
#   --ignore-combinational-warning
#       Pass through to the build script. Ignore the ABC combinational network
#       warning. Not recommended unless this warning is already understood.
#
#   --no-warning-pause
#       Pass through to the build script. Do not pause when warnings are found.
#
#   --ulx3s-board-version <version>
#   --ulx3s-board-version=<version>
#   --board-version <version>
#   --board-version=<version>
#       Pass through to the build script. Select the ULX3S board version.
#       Example values: v20, v316
#
#   --port <port>
#       Serial port to use for tests. If omitted, the default below is used.
#
# Examples:
#
#   ./run_tests.sh
#   ./run_tests.sh --port /dev/ttyS11
#   ./run_tests.sh --with-build --loopback --port /dev/ttyS11
#   ./run_tests.sh --with-build --deep-loopback --ignore-combinational-warning
#   ./run_tests.sh --with-build --ulx3s-board-version v316
#   ./run_tests.sh --with-build --board-version=v20
#
# Windows: PORT=COM8
# Linux:   PORT=/dev/ttyUSB0
# macOS:   PORT=/dev/tty.usbserial-0001
# WSL:     PORT=/dev/ttyS8

PORT=/dev/ttyS12

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
EXPECT_BOARD_VERSION_VALUE=0
PAUSE_FOR_TEST=0
BUILD_ARGS=""

# ------------------------------------------------------------------------------
# Parameter processing
# ------------------------------------------------------------------------------
for arg in "$@"; do
    FOUND_KNOWN_ARG=0

    # --------------------------------------------------------------------------
    # First look at options that require a parameter
    # --------------------------------------------------------------------------
    # Handle value for previous --port
    if [ "$EXPECT_PORT_VALUE" -eq 1 ]; then
        PORT="$arg"
        EXPECT_PORT_VALUE=0

        FOUND_KNOWN_ARG=1
        echo "Using port: $PORT"
        continue
    fi

    # Handle value for previous --ulx3s-board-version or --board-version
    if [ "$EXPECT_BOARD_VERSION_VALUE" -eq 1 ]; then
        EXPECT_BOARD_VERSION_VALUE=0

        FOUND_KNOWN_ARG=1
        BUILD_ARGS="$BUILD_ARGS --ulx3s-board-version=$arg"
        echo "Using ULX3S board version: $arg"
        continue
    fi

    if [ "$arg" = "--port" ]; then
        echo "Will use specified port instead of $PORT"
        FOUND_KNOWN_ARG=1
        EXPECT_PORT_VALUE=1
    fi

    if [ "$arg" = "--ulx3s-board-version" ]; then
        FOUND_KNOWN_ARG=1
        EXPECT_BOARD_VERSION_VALUE=1
    fi

    if [ "$arg" = "--board-version" ]; then
        FOUND_KNOWN_ARG=1
        EXPECT_BOARD_VERSION_VALUE=1
    fi

    case "$arg" in
        --ulx3s-board-version=*)
            FOUND_KNOWN_ARG=1
            BOARD_VERSION="${arg#--ulx3s-board-version=}"

            if [ -z "$BOARD_VERSION" ]; then
                echo "Error: --ulx3s-board-version requires a value"
                exit 1
            fi

            BUILD_ARGS="$BUILD_ARGS --ulx3s-board-version=$BOARD_VERSION"
            echo "Using ULX3S board version: $BOARD_VERSION"
            ;;
        --board-version=*)
            FOUND_KNOWN_ARG=1
            BOARD_VERSION="${arg#--board-version=}"

            if [ -z "$BOARD_VERSION" ]; then
                echo "Error: --board-version requires a value"
                exit 1
            fi

            BUILD_ARGS="$BUILD_ARGS --ulx3s-board-version=$BOARD_VERSION"
            echo "Using ULX3S board version: $BOARD_VERSION"
            ;;
    esac

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

    if [ "$arg" = "--pause-for-test" ]; then
        FOUND_KNOWN_ARG=1
        PAUSE_FOR_TEST=1
        echo "Will prompt to continue tests"
    fi

    if [ "$FOUND_KNOWN_ARG" -eq 0 ]; then
        echo ""
        echo "Unknown argument: $arg"
        echo ""
        echo "Usage: $0 [--with-build] [--loopback] [--deep-loopback]"
        echo "          [--ignore-combinational-warning] [--no-warning-pause]"
        echo "          [--ulx3s-board-version <version>] [--ulx3s-board-version=<version>]"
        echo "          [--board-version <version>] [--board-version=<version>]"
        echo "          [--port <port>]"
        echo "          [--pause-for-test]"
        echo ""
        echo "  --with-build: Build and flash before running tests"
        echo "  --loopback: Enable basic loopback mode for build"
        echo "  --deep-loopback: Enable deeper loopback mode for build"
        echo "  --ignore-combinational-warning: Ignore ABC combinational network warning"
        echo "  --no-warning-pause: Do not pause for warnings"
        echo "  --ulx3s-board-version <version>: Select ULX3S board version for build"
        echo "  --ulx3s-board-version=<version>: Select ULX3S board version for build"
        echo "  --board-version <version>: Alias for --ulx3s-board-version"
        echo "  --board-version=<version>: Alias for --ulx3s-board-version"
        echo "  --port <port>: Serial port to use for tests"
        echo "  --pause-for-test: Pause before tests to allow setup"
        exit 1
    fi 
done

if [ "$EXPECT_PORT_VALUE" -eq 1 ]; then
    echo "Error: --port requires a value"
    exit 1
fi

if [ "$EXPECT_BOARD_VERSION_VALUE" -eq 1 ]; then
    echo "Error: --ulx3s-board-version requires a value"
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
# Optionally pause before tests to allow user to connect test equipment, etc.
# ------------------------------------------------------------------------------
if [ "$PAUSE_FOR_TEST" -eq 1 ]; then
    read -r -p "Press Enter to continue..."
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

    python ./tt_ulx3s_trng_uart_test.py --port "$PORT"              || exit 1

    python ./tt_ulx3s_trng_repro_test.py --port  "$PORT"            || exit 1
fi

echo "Port used: $PORT"
