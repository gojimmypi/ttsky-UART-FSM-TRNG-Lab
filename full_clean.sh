#!/bin/bash
#
# Copyright (c) 2026 gojimmypi
# SPDX-License-Identifier: Apache-2.0
#
# file: full_clean.sh
#

set -e

echo "Starting full clean..."
# Run shellcheck to ensure this is a good script.
# Specify the executable shell checker you want to use:
MY_SHELLCHECK="shellcheck"

# Check if the executable is available in the PATH
if command -v "$MY_SHELLCHECK" >/dev/null 2>&1; then
    # Run your command here
    "$MY_SHELLCHECK" -x "${BASH_SOURCE[0]}" || exit 1
else
    echo "$MY_SHELLCHECK is not installed. Please install it if changes to this script have been made."
fi

rm -rf ./build

rm -f ./test/results.xml
rm -f ./test/*.vcd
rm -f ./test/*.vvp
rm -f ./test/*.fst
rm -f ./test/gtkwave_output.jpg

rm -f ./test-hw/*.bin

rm -f  ./ulx3s/build_output.log
rm -f  ./ulx3s/build_output.log.old
rm -f  ./ulx3s/putty.log
rm -f  ./ulx3s/ulx3s.bit
rm -f  ./ulx3s/ulx3s_out.config

rm -f  ./ulx3s/ESP32/CMakeLists.old
rm -f  ./ulx3s/ESP32/CMakeLists.txt.old
rm -rf ./ulx3s/ESP32/sdkconfig.bak

rm -rf ./ulx3s/ESP32/build

BAK_FILES="$(find . -type f -iname "*.bak" -print)"

if [ -n "$BAK_FILES" ]; then
    echo "Found .bak files:"
    echo "$BAK_FILES"
fi

echo "Completed full clean."
