#!/bin/bash
#
# Copyright (c) 2026 gojimmypi
# SPDX-License-Identifier: Apache-2.0
#
# file: scripts/clean_files.sh
#

# Stop on all failed commands
# set -e

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

#   ./target_pdk.v  is typically read-only

for f in \
  ./project.v \
  ./project_config.v \
  ./tt_um_main.v \
  ./JTAG/jtag_core.v \
  ./PINS/pin_id_core.v \
  ./SPI/spi_slave.v \
  ./TRNG/trng_cfg_ascii_core.v \
  ./TRNG/trng_lab_core.v \
  ./TRNG/trng_stub.v \
  ./UART/uart_rx_min.v \
  ./UART/uart_trng_ascii_core.v \
  ./UART/uart_tx_min.v 
do
    echo "Processing: $f"

    if [ ! -e "$f" ]; then
        echo "File not found: ${f}"
    fi

    # show offending characters first
    LC_ALL=C grep -nP "[^\x00-\x7F]" "$f"

    # convert safely via temp file
    tmp="$f.tmp"
    iconv -f utf-8 -t ascii//TRANSLIT "$f" > "$tmp" && mv "$tmp" "$f"
done
