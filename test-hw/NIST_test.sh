#!/bin/bash
#
# Copyright (c) 2026 gojimmypi
# SPDX-License-Identifier: Apache-2.0
#

THE_FILE="trng_conditioned_2MiB.bin"
PORT="${PORT:-/dev/ttyS12}"
BYTES=2097152
BITS_PER_STREAM=1048576
RUNS=10

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



TEST_HW_DIR="$(pwd)"
STS_DIR="$(cd ../../sts-2.1.2 && pwd)"
RESULTS_DIR="$STS_DIR/experiments/AlgorithmTesting"

if [ ! -x "./capture_trng_raw_uart.py" ]; then
    echo "Missing executable: ./capture_trng_raw_uart.py"
    exit 1
fi

if [ ! -x "$STS_DIR/assess" ]; then
    echo "Missing executable: $STS_DIR/assess"
    exit 1
fi

if [ ! -d "$RESULTS_DIR" ]; then
    echo "Missing STS results directory: $RESULTS_DIR"
    exit 1
fi

reset_results_dir() {
    local dir="$1"

    find "$dir" -type f \( \
        -name "results.txt" -o \
        -name "stats.txt" -o \
        -name "data*.txt" -o \
        -name "freq.txt" -o \
        -name "finalAnalysisReport.txt" \
    \) -delete

    find "$dir" -type f -path "*/experiments/*" -delete 2>/dev/null || true
}

save_old_results() {
    local suffix="$1"

    if [ -f "$RESULTS_DIR/finalAnalysisReport.txt" ]; then
        echo "Saving old STS results with suffix .$suffix"

        find "$RESULTS_DIR" -type f \( \
            -name "results.txt" -o \
            -name "stats.txt" -o \
            -name "data*.txt" -o \
            -name "freq.txt" -o \
            -name "finalAnalysisReport.txt" \
        \) | while IFS= read -r f; do
            cp -f "$f" "$f.$suffix"
        done
    else
        echo "No old finalAnalysisReport.txt found before run $suffix"
    fi
}

for x in $(seq 1 "$RUNS"); do
    echo
    echo "======================================================================"
    echo "Run $x of $RUNS"
    echo "======================================================================"

    cd "$TEST_HW_DIR"

    echo "Capturing $BYTES bytes to $THE_FILE from $PORT (fast baud, conditioned)"
    ./capture_trng_raw_uart.py \
        --port "$PORT" \
        --bytes "$BYTES" \
        --out "$THE_FILE" \
        --fast-baud \
        --conditioned

    cd "$STS_DIR"

    save_old_results "$x"

    echo "Initializing new STS results directory"
    reset_results_dir "$RESULTS_DIR"

    echo "Calling checking file $TEST_HW_DIR/$THE_FILE"


    # NIST STS assess is interactive.  Feed the answers with a heredoc:
    #
    #   ./assess "$BITS_PER_STREAM"
    #       Number of bits per tested sequence.
    #       For this script: 1,048,576 bits = 128 KiB.
    #
    #   0
    #       Generator selection: [0] Input File.
    #
    #   $TEST_HW_DIR/$THE_FILE
    #       Binary TRNG capture file to test.
    #
    #   1
    #       Statistical tests menu: apply all tests.
    #
    #   0
    #       Parameter adjustment menu: continue with default parameters.
    #
    #   16
    #       Number of bitstreams/sequences.
    #       16 * 1,048,576 bits = 16,777,216 bits = 2 MiB.
    #
    #   1
    #       Input file format: [1] Binary, each byte contains 8 bits.
    #
    set +e
    ./assess "$BITS_PER_STREAM" <<EOF
0
$TEST_HW_DIR/$THE_FILE
1
0
16
1
EOF
    assess_rc=$?
    set -e

    echo "assess exit code: $assess_rc"

    RUN_RESULTS_DIR="$STS_DIR/experiments/AlgorithmTesting.$x"
    RUN_REPORT="$RUN_RESULTS_DIR/finalAnalysisReport.txt"

    rm -rf "$RUN_RESULTS_DIR"
    cp -a "$RESULTS_DIR" "$RUN_RESULTS_DIR"

    echo "Saved full results directory: $RUN_RESULTS_DIR"

    echo
    echo "Starred STS results for run $x:"
    if [ -f "$RUN_REPORT" ]; then
        grep '\*' "$RUN_REPORT" || echo "No starred lines"
    else
        echo "WARNING: no finalAnalysisReport.txt found in $RUN_RESULTS_DIR"
    fi
done

echo
echo "done"
