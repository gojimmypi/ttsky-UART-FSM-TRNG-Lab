#!/bin/bash
#
# Copyright (c) 2026 gojimmypi
# SPDX-License-Identifier: Apache-2.0
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
REMINDER_COMPLETE=1

for arg in "$@"; do
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

    if [ "$FOUND_KNOWN_ARG" -eq 0 ]; then
        echo "Unknown argument: $arg"
        exit 1
    fi

    if [ "$FOUND_KNOWN_ARG" -eq 0 ]; then 
        echo "Usage: $0 [--loopback] [--deep-loopback]"
        echo "  --loopback: Enable basic loopback mode for build"
        echo "  --deep-loopback: Enable deeper loopback mode for build"
        exit 1
    fi 
done

make clean

make $MAKE_ARGS 2>&1 | tee error.log

grep -i error error.log

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
