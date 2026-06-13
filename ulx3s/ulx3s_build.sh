#!/bin/bash
#
# Copyright (c) 2026 gojimmypi
# SPDX-License-Identifier: Apache-2.0
#
# See ATTRIBUTION.md for third-party sources and credits.
#
# file: ulx3s_build.sh
#
# This script is used to build the ULX3S FPGA project using the make tool. 
# Optional WSL should be auto-detected
#
#
# ./ulx3s_build.sh
# ./ulx3s_build.sh --loopback
# ./ulx3s_build.sh --deep-loopback
# ./ulx3s_build.sh --ulx3s-board-version=v20
# ./ulx3s_build.sh --ulx3s-board-version=v316
#
set -e
set -o pipefail

OUTPUT_LOG="build_output.log"

# Run shellcheck to ensure this is a good script.
# Specify the executable shell checker you want to use:
MY_SHELLCHECK="shellcheck"

# Check if the executable is available in the PATH
if command -v "$MY_SHELLCHECK" >/dev/null 2>&1; then
    # Run your command here
    shellcheck "$0"  
else
    echo "$MY_SHELLCHECK is not installed. Please install it if changes to this script have been made."
fi

# Default: no loopback
MAKE_ARGS=""
FOUND_KNOWN_ARG=0
IGNORE_COMBINATIONAL_WARNING=0
NO_WARNING_PAUSE=0
REMINDER_COMPLETE=1
ORIGINAL_ARGS=("$@")

print_usage() {
    echo "Usage: $0 [--loopback] [--deep-loopback] [--ulx3s-board-version=VERSION]"
    echo "  --loopback: Enable basic loopback mode for build"
    echo "  --deep-loopback: Enable deeper loopback mode for build"
    echo "  --ulx3s-board-version=VERSION: Pass ULX3S_BOARD_VERSION=VERSION to make"
    echo "  --board-version=VERSION: Short alias for --ulx3s-board-version=VERSION"
    echo "  --ignore-combinational-warning: Ignore ABC combinational network warning (not recommended)"
    echo "  --no-warning-pause: Do not pause to review ignored warnings"
}

validate_board_version() {
    local board_version

    board_version="$1"

    if [ -z "$board_version" ]; then
        echo "Error: ULX3S board version must not be empty"
        print_usage
        exit 1
    fi

    case "$board_version" in
        *[!A-Za-z0-9_]*)
            echo "Error: ULX3S board version may contain only letters, numbers, and underscores"
            echo "For example: v20, v307, or v316"
            exit 1
            ;;
    esac
}

while [ "$#" -gt 0 ]; do
    arg="$1"
    FOUND_KNOWN_ARG=0

    # When editing MAKE_ARGS, remember to keep the Makefile arguments in sync.

    # A basic loopback that tests high level tx/rx communication
    if [ "$arg" = "--loopback" ]; then
        FOUND_KNOWN_ARG=1
        REMINDER_COMPLETE=0
        echo "Enabling loopback mode for build"
        MAKE_ARGS="$MAKE_ARGS FORCE_LOOPBACK=1"
    fi

    # A deeper and more complex logic loopback that tests more of the internal logic and is more likely to catch issues
    if [ "$arg" = "--deep-loopback" ]; then
        FOUND_KNOWN_ARG=1
        REMINDER_COMPLETE=0
        echo "Enabling deep loopback mode for build"
        MAKE_ARGS="$MAKE_ARGS FORCE_DEEP_LOOPBACK=1"
    fi

    if [ "$arg" = "--ignore-combinational-warning" ]; then
        FOUND_KNOWN_ARG=1
        IGNORE_COMBINATIONAL_WARNING=1
        echo "Ignoring combinational network message for build"
    fi

    if [ "$arg" = "--no-warning-pause" ]; then
        FOUND_KNOWN_ARG=1
        NO_WARNING_PAUSE=1
        echo "Will not pause to review warnings"
    fi

    if [ "$arg" = "--ulx3s-board-version" ] || [ "$arg" = "--board-version" ]; then
        FOUND_KNOWN_ARG=1
        shift

        if [ "$#" -eq 0 ]; then
            echo "Error: $arg requires a value"
            print_usage
            exit 1
        fi

        validate_board_version "$1"

        echo "Using ULX3S board version: $1"
        MAKE_ARGS="$MAKE_ARGS ULX3S_BOARD_VERSION=$1"
    fi

    case "$arg" in
        --ulx3s-board-version=*|--board-version=*)
            FOUND_KNOWN_ARG=1
            ULX3S_BOARD_VERSION_ARG="${arg#*=}"

            validate_board_version "$ULX3S_BOARD_VERSION_ARG"

            echo "Using ULX3S board version: $ULX3S_BOARD_VERSION_ARG"
            MAKE_ARGS="$MAKE_ARGS ULX3S_BOARD_VERSION=$ULX3S_BOARD_VERSION_ARG"
            ;;
    esac

    if [ "$FOUND_KNOWN_ARG" -eq 0 ]; then
        echo "Unknown argument: $arg"
        print_usage
        exit 1
    fi

    shift
done

make clean || exit 1
MAKE_ARGS_ARRAY=()

if [ -n "${MAKE_ARGS:-}" ]; then
    # shellcheck disable=SC2206
    MAKE_ARGS_ARRAY=($MAKE_ARGS)
fi

# Save the prior output for comparison
if [ -f "$OUTPUT_LOG" ]; then 
    mv "$OUTPUT_LOG" "$OUTPUT_LOG".old || exit 1
fi

#********************************************************
# Run make and capture output
#********************************************************
make "${MAKE_ARGS_ARRAY[@]}" 2>&1 | tee $OUTPUT_LOG
make_status=${PIPESTATUS[0]}

if [ "$make_status" -ne 0 ]; then
    echo "make failed with status $make_status"
    exit "$make_status"
fi

echo ""
echo "Scanning build log..."
echo "IGNORE_COMBINATIONAL_WARNING=$IGNORE_COMBINATIONAL_WARNING"

if [ "$IGNORE_COMBINATIONAL_WARNING" -eq "0" ]; then
    echo "Checking for warnings or errors..."
    # Check for any warnings or errors in the build log
    if grep -Ei "error|warning" $OUTPUT_LOG ; then
        echo ""
        echo "Build FAILED: warnings or errors detected"
        exit 1
    fi
else
    echo "NOTE: Ignoring ABC combinational network warning as requested"

    if [ "$NO_WARNING_PAUSE" -eq "0" ]; then
        # Show the ABC warning (non-fatal) and pause
        if grep -i "ABC: Warning: The network is combinational" $OUTPUT_LOG; then
            echo ""
            echo "NOTE: ABC combinational network warning (ignored)"
            read -r -p "Press Enter to continue..."
         fi
    fi

    # Now check everything else (excluding that warning)
    if grep -Ei "error|warning" $OUTPUT_LOG | grep -vi "ABC: Warning: The network is combinational"; then
        echo ""
        echo "Build FAILED: warnings or errors detected"
        exit 1
    fi
fi

echo "Build PASSED"

for arg in "${ORIGINAL_ARGS[@]}"; do
    if [ "$arg" = "--loopback" ]; then
        REMINDER_COMPLETE=1
        echo "Reminder: Enabling loopback mode for build"
    fi
    if [ "$arg" = "--deep-loopback" ]; then
        REMINDER_COMPLETE=1
        echo "Reminder: Enabling deep loopback mode for build"
    fi
done

if [ "$REMINDER_COMPLETE" -eq 0 ]; then
    echo "Warning: unresolved build reminder. Check config."
    exit 1
fi
