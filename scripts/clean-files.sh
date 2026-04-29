#!/bin/bash

for f in \
  ./project.v \
  ./tt_um_uart_trng_ascii.v \
  ./UART/TRNG/trng_cfg_ascii_core.v \
  ./UART/TRNG/trng_stub.v \
  ./UART/uart_rx_min.v \
  ./UART/uart_trng_ascii_core.v \
  ./UART/uart_tx_min.v 
do
  echo "Processing: $f"

  # show offending characters first
  LC_ALL=C grep -nP "[^\x00-\x7F]" "$f"

  # convert safely via temp file
  tmp="$f.tmp"
  iconv -f utf-8 -t ascii//TRANSLIT "$f" > "$tmp" && mv "$tmp" "$f"
done
