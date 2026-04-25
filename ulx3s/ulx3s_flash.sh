#!/bin/bash
#
# Copyright (c) 2026 gojimmypi
# SPDX-License-Identifier: Apache-2.0
#
# file: ulx3s_flash.sh
#
# This script is used to program the ULX3S FPGA board using the fujprog tool. 
# Optional WSL should be auto-detected
#

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

if [ -n "$WSL_DISTRO_NAME" ]; then
    # we found a non-blank WSL environment distro name
    # This script is intended to be run inside WSL (Windows Subsystem for Linux) to program the ULX3S FPGA board using the fujprog tool.
    ./fujprog-v48-win64.exe ulx3s.bit
else
    ./fujprog ulx3s.bit
fi
