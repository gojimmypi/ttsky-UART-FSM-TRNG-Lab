#!/bin/bash
#
# Copyright (c) 2026 gojimmypi
# SPDX-License-Identifier: Apache-2.0
#
# file: scripts/verilator_lint.sh
#
# This script is used to lint the Verilog project using Verilator.
#
# The /.github/workflows/gds.yaml also does this, but this script is intended to be run locally by developers 
# to check their changes before pushing them to GitHub, where the CI will also check them.
#
# Do not move this file. Referenced by TT 4337 Documentation https://app.tinytapeout.com/projects/4337

# Run shellcheck to ensure this is a good script.
# Specify the executable shell checker you want to use:
MY_SHELLCHECK="shellcheck"

# Check if the executable is available in the PATH
if command -v "$MY_SHELLCHECK" >/dev/null 2>&1; then
    # Run your command here
    shellcheck "$0" || exit 1
else
    echo "$MY_SHELLCHECK is not installed. Please install it if changes to this script have been made."
fi

pushd ../src || exit 1
    echo "Calling verilator to lint the Verilog project..."
    verilator --lint-only -Wall                                      \
              --top-module tt_um_gojimmypi_ttgf_UART_FSM_TRNG_Lab   \
              project.v
popd || exit 1
