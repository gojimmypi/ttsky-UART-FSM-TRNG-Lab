#!/bin/bash
#
# Copyright (c) 2026 gojimmypi
# SPDX-License-Identifier: Apache-2.0
#
# file: my_test.sh
#

set -euo pipefail

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

echo "********************************************************************"
echo "Check for generated demoboard _tt_fpga_top.v..."
echo "********************************************************************"
if [ -e "../src/_tt_fpga_top.v" ]; then
    echo "Error: Found ../src/_tt_fpga_top.v generated file. Remove it before running simulation tests"
    exit 1
else    
    echo "Confirmed there's no stray ../src/_tt_fpga_top.v"
fi

echo "********************************************************************"
echo "Clean..."
echo "********************************************************************"
rm -f tb tb.vcd tb.fst

rm -f sim_output.vvp tb_tt_um_main_jtag.vcd tb_tt_um_main_jtag.vvp

# Test with not modulke `tb`
echo "********************************************************************"
echo "Call iverilog..."
echo "********************************************************************"
iverilog -o sim_output.vvp \
    -DIS_MY_IVERILOG_SIMULATION=1 \
    -I../src \
    -s tb \
    tb.v \
    ../src/project.v \
    ../src/tt_um_main.v \
    ../src/JTAG/jtag_core.v \
    ../src/SPI/spi_slave.v \
    ../src/UART/uart_rx_min.v \
    ../src/UART/uart_tx_min.v \
    ../src/UART/uart_trng_ascii_core.v \
    ../src/TRNG/trng_lab_core.v \
    ../src/TRNG/trng_cfg_ascii_core.v 

echo "iverilog completed"

# Convert 
echo "********************************************************************"
echo "Running simulation..."
echo "********************************************************************"
vvp sim_output.vvp
echo "********************************************************************"
echo "Simulation completed."
echo "********************************************************************"

if [ ! -s tb.vcd ]; then
    echo "ERROR: tb.vcd was not created or is empty."
    exit 1
fi


# WSL1 + Cygwin/X: force TCP X11 display if DISPLAY is not already set.
if grep -qi microsoft /proc/version && [ -z "${DISPLAY:-}" ]; then
    export DISPLAY=localhost:0.0
fi

if [ -z "${DISPLAY:-}" ]; then
    echo "No DISPLAY set."
    echo "For WSL1 + Cygwin/X, try:"
    echo "    export DISPLAY=localhost:0.0"
    echo "    gtkwave tb.vcd"
    exit 0
fi

echo "Using DISPLAY=${DISPLAY:-<unset>}"

# View waveform if GTKWave and a display are available.
if ! command -v gtkwave >/dev/null 2>&1; then
    echo "GTKWave is not installed."
    echo "Open later with: gtkwave tb.vcd"
    exit 0
fi


echo "Opening GTKWave to view tb.vcd..."

gtkwave tb.vcd >/tmp/gtkwave.log 2>&1 &
gtkwave_pid=$!

sleep 1

if ! kill -0 "$gtkwave_pid" 2>/dev/null; then
    cat /tmp/gtkwave.log
    echo "********************************************************************"
    echo "GTKWave failed to start."
    if [ -n "${WSL_DISTRO_NAME:-}" ]; then
        echo "WSL Detected!"
        echo "Did you run \"startxwin -- -listen tcp -ac\" from a cygwin prompt?"
    fi
fi
