#!/bin/bash
#
# Copyright (c) 2026 gojimmypi
# SPDX-License-Identifier: Apache-2.0
#
# file: test/jtag_test.sh
#

# Stop on all failed commands
set -e

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

iverilog -g2012 -Wall -DSIM_JTAG_CORE_TB -o tb_jtag_core.vvp \
    tb_jtag_core.v \
    ../src/JTAG/jtag_core.v

vvp tb_jtag_core.vvp
