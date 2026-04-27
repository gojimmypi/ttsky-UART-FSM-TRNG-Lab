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
#
set -e
set -o pipefail

OUTPUT_LOG="build_output.log"

# Run shell check to ensure this a good script.
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

for arg in "$@"; do
    FOUND_KNOWN_ARG=0

    # When editing MAKE_ARGS, don't forget to edit the Makefile!

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

    if [ "$FOUND_KNOWN_ARG" -eq 0 ]; then
        echo "Unknown argument: $arg"
        exit 1
    fi

    if [ "$FOUND_KNOWN_ARG" -eq 0 ]; then 
        echo "Usage: $0 [--loopback] [--deep-loopback]"
        echo "  --loopback: Enable basic loopback mode for build"
        echo "  --deep-loopback: Enable deeper loopback mode for build"
        echo "  --ignore-combinational-warning: Ignore ABC combinational network warning (not recommended)"
        exit 1
    fi 
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

for arg in "$@"; do
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
