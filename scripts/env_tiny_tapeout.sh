#!/bin/bash
#
# Copyright (c) 2026 gojimmypi
# SPDX-License-Identifier: Apache-2.0
#
# file: scripts/env_tiny_tapeout.sh
#

echo "**************************************************************************"
echo "**  Begin ${BASH_SOURCE[0]} from ${PWD}"
echo "**************************************************************************"

# Windows: PORT=COM5
# WSL:     PORT=/dev/ttyS5
# Linux:   PORT=/dev/ttyUSB5 or /dev/ttyACM5
# macOS:   PORT=/dev/tty.usbserial-0005

if [ -z "${MY_TT_PORT:-}" ]; then
    MY_TT_PORT="/dev/ttyS6"
fi

if [ -z "${MY_WORKSPACE:-}" ]; then
    MY_WORKSPACE="/mnt/c/workspace"
fi

# The cloned repository name. For example: "ttsky-UART-FSM-TRNG-Lab" or "ttgf-UART-FSM-TRNG-Lab"
if [ -z "${MY_PROJECT_NAME:-}" ]; then
    MY_PROJECT_NAME="$(basename "$(dirname "$PWD")")"
fi

# Run shellcheck to ensure this is a good script.
# Specify the executable shell checker you want to use:
MY_SHELLCHECK="shellcheck"

# Check if the executable is available in the PATH
if command -v "$MY_SHELLCHECK" >/dev/null 2>&1; then
    # Run your command here
    # echo "Shellchecking source: ${BASH_SOURCE[0]}"
    "$MY_SHELLCHECK" "${BASH_SOURCE[0]}" || return 1
else
    echo "$MY_SHELLCHECK is not installed. Please install it if changes to this script have been made."
fi

echo "Setting up environment variables for Tiny Tapeout FPGA project..."

export TT_PORT=${MY_TT_PORT}
echo  "TT_PORT:              ${TT_PORT}"

# For example on WSL, the C:\workspace directory is mounted at /mnt/c/workspace
export WORKSPACE=${MY_WORKSPACE}
echo  "WORKSPACE:            ${WORKSPACE}"

# Typically the name of the repo, unless manually specified. See MY_PROJECT_NAME, above
# See the src/project.v for the top module name
export TT_PROJECT_NAME=${MY_PROJECT_NAME}
echo  "TT_PROJECT_NAME:      ${TT_PROJECT_NAME}"

# For example "ttsky_UART_FSM_TRNG_Lab" (replace dashes with underscores)
export TT_PROJECT_NAME_ALT="${TT_PROJECT_NAME//-/_}"
echo  "TT_PROJECT_NAME_ALT:  ${TT_PROJECT_NAME_ALT}"

# For example:  "/mnt/c/workspace/ttgf-UART-FSM-TRNG-Lab"  or  "/mnt/c/workspace/ttsky-UART-FSM-TRNG-Lab"
export TT_PROJECT_ROOT="${WORKSPACE}/${TT_PROJECT_NAME}"
echo  "TT_PROJECT_ROOT:      ${TT_PROJECT_ROOT}"

# For example:  "tt_um_gojimmypi_ttgf_UART_FSM_TRNG_Lab"  or  "tt_um_gojimmypi_ttsky_UART_FSM_TRNG_Lab"
export TT_TOP_NAME="tt_um_${USER}_${TT_PROJECT_NAME_ALT}"
echo  "TT_TOP_NAME:          ${TT_TOP_NAME}"

# For example:  "/mnt/c/workspace/tt-support-tools-gojimmypi"
export TT_TOOLS=${WORKSPACE}/tt-support-tools-${USER}
echo  "TT_TOOLS:             ${TT_TOOLS}"
