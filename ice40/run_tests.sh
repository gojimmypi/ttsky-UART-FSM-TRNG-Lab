#!/bin/bash
#
# Copyright (c) 2026 gojimmypi
# SPDX-License-Identifier: Apache-2.0
#
# file: ice40/run_tests.sh
#

UART_PORT=/dev/ttyS5
set -e
set -o pipefail


# The TT port is the board with the repl prompt, NOT the connected UART
if [ -z "$TT_PORT" ]; then
    echo  "info: no TT_PORT found" >&2
    exit 1
else
    echo "TT_PORT:   ${TT_PORT}"
fi

# WARNING: This is NOT the TT_PORT for the Tiny Tapeout Demoboard.
# This port is the external UART connected to the PMOD pins!
echo "UART_PORT: ${UART_PORT}"

# Run shell check to ensure this a good script.
# Specify the executable shell checker you want to use:
MY_SHELLCHECK="shellcheck"

# Check if the executable is available in the PATH
if command -v "$MY_SHELLCHECK" >/dev/null 2>&1; then
    # Run your command here 
    "$MY_SHELLCHECK" -x "${BASH_SOURCE[0]}" || exit 1
else
    echo "$MY_SHELLCHECK is not installed. Please install it if changes to this script have been made."
fi

# Setup environment
echo "**************************************************************************"
echo " Setup environment"
echo "**************************************************************************"
. ./env_ice40.sh

echo "**************************************************************************"
echo "Calling project reset script on port ${TT_PORT}"
echo "**************************************************************************"
./project_reset.sh || exit 1


echo "**************************************************************************"
echo "Calling test scripts on port ${UART_PORT}"
echo "**************************************************************************"

python ../test-hw/tt_ulx3s_uart_test.py --port "$UART_PORT"                   || exit 1

python ../test-hw/tt_ulx3s_uart_test.py --port "$UART_PORT" --reset-registers || exit 1

python ../test-hw/tt_ulx3s_trng_uart_test.py --port "$UART_PORT"              || exit 1

python ../test-hw/tt_ulx3s_trng_repro_test.py --port  "$UART_PORT"            || exit 1

python ../test-hw/tt_ulx3s_uart_test.py --port "$UART_PORT" --reset-registers || exit 1
