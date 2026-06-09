#!/bin/bash
#
# Copyright (c) 2026 gojimmypi
# SPDX-License-Identifier: Apache-2.0
#
# file: ice40/run_tests.sh
#

set -e
set -o pipefail

echo "**************************************************************************"
echo "**  Begin ${BASH_SOURCE[0]} from ${PWD}"
echo "**************************************************************************"

# The TT_UART_PORT is the external USB TTY device, typically connected to IN3/Rx and OUT4/Tx.
MY_TT_UART_PORT=/dev/ttyS5

export TT_UART_PORT=${MY_TT_UART_PORT}

# WARNING: This is NOT the TT_PORT for the Tiny Tapeout Demoboard.
# This port is the external UART connected to the PMOD pins!
    echo "TT_UART_PORT: ${TT_UART_PORT}"

# The TT port is the board with the repl prompt, NOT the connected external UART adapter.
if [ -z "$TT_PORT" ]; then
    echo  "info: no TT_PORT found" >&2
    exit 1
else
    echo "TT_PORT:      ${TT_PORT}"
fi

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
echo "**  Setup environment"
echo "**************************************************************************"
. ./env_ice40.sh

echo "**************************************************************************"
echo "**  Calling project reset script on port ${TT_PORT}"
echo "**************************************************************************"
./project_reset.sh || exit 1


echo "**************************************************************************"
echo "**  Calling test scripts on port ${TT_UART_PORT}"
echo "**************************************************************************"

python ../test-hw/tt_ulx3s_uart_test.py --port "$TT_UART_PORT"                   || exit 1

python ../test-hw/tt_ulx3s_uart_test.py --port "$TT_UART_PORT" --reset-registers || exit 1

python ../test-hw/tt_ulx3s_trng_uart_test.py --port "$TT_UART_PORT"              || exit 1

python ../test-hw/tt_ulx3s_trng_repro_test.py --port  "$TT_UART_PORT"            || exit 1

python ../test-hw/tt_ulx3s_uart_test.py --port "$TT_UART_PORT" --reset-registers || exit 1

echo "**************************************************************************"
echo "**  Done. Ports used:"
echo "**************************************************************************"
echo "TT_UART_PORT: ${TT_UART_PORT}"
echo "TT_PORT:      ${TT_PORT}"
