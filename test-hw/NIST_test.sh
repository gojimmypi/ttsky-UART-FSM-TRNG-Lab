#!/bin/bash
#
# Copyright (c) 2026 gojimmypi
# SPDX-License-Identifier: Apache-2.0
#

THE_FILE_BASE="trng_conditioned_2MiB"
PORT="${PORT:-/dev/ttyS12}"
BYTES=2097152
BITS_PER_STREAM=1048576
STREAMS_PER_RUN=16
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
RESULTS_PARENT_DIR="$STS_DIR/experiments"
RESULTS_DIR="$RESULTS_PARENT_DIR/AlgorithmTesting"
WORK_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/nist_sts_parallel.XXXXXXXXXX")"

cleanup() {
    rm -rf "$WORK_ROOT"
}

trap cleanup EXIT

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

run_assess() {
    local x="$1"
    local capture_file="$2"
    local work_sts_dir="$WORK_ROOT/sts-2.1.2.$x"
    local work_results_dir="$work_sts_dir/experiments/AlgorithmTesting"
    local run_results_dir="$RESULTS_PARENT_DIR/AlgorithmTesting.$x"
    local run_report="$run_results_dir/finalAnalysisReport.txt"
    local assess_rc

    echo
    echo "======================================================================"
    echo "STS run $x of $RUNS"
    echo "======================================================================"

    cd "$work_sts_dir"

    echo "Initializing worker STS results directory for run $x"
    reset_results_dir "$work_results_dir"

    echo "Calling checking file $capture_file"


    # NIST STS assess is interactive.  Feed the answers with a heredoc:
    #
    #   ./assess "$BITS_PER_STREAM"
    #       Number of bits per tested sequence.
    #       For this script: 1,048,576 bits = 128 KiB.
    #
    #   0
    #       Generator selection: [0] Input File.
    #
    #   $capture_file
    #       Binary TRNG capture file to test.
    #
    #   1
    #       Statistical tests menu: apply all tests.
    #
    #   0
    #       Parameter adjustment menu: continue with default parameters.
    #
    #   $STREAMS_PER_RUN
    #       Number of bitstreams/sequences.
    #       16 * 1,048,576 bits = 16,777,216 bits = 2 MiB.
    #
    #   1
    #       Input file format: [1] Binary, each byte contains 8 bits.
    #
    set +e
    ./assess "$BITS_PER_STREAM" <<EOF_ASSESS
0
$capture_file
1
0
$STREAMS_PER_RUN
1
EOF_ASSESS
    assess_rc=$?
    set -e

    echo "assess exit code for run $x: $assess_rc"

    rm -rf "$run_results_dir"
    cp -a "$work_results_dir" "$run_results_dir"

    echo "Saved full results directory: $run_results_dir"

    echo
    echo "Starred STS results for run $x:"
    if [ -f "$run_report" ]; then
        grep '\*' "$run_report" || echo "No starred lines"
    else
        echo "WARNING: no finalAnalysisReport.txt found in $run_results_dir"
    fi

    return "$assess_rc"
}

for x in $(seq 1 "$RUNS"); do
    capture_file="$TEST_HW_DIR/$THE_FILE_BASE.$x.bin"

    echo
    echo "======================================================================"
    echo "Capture $x of $RUNS"
    echo "======================================================================"

    cd "$TEST_HW_DIR"

    echo "Capturing $BYTES bytes to $capture_file from $PORT (fast baud, conditioned)"
    ./capture_trng_raw_uart.py \
        --port "$PORT" \
        --bytes "$BYTES" \
        --out "$capture_file" \
        --fast-baud \
        --conditioned

done

for x in $(seq 1 "$RUNS"); do
    worker_dir="$WORK_ROOT/sts-2.1.2.$x"

    echo "Preparing isolated STS worker directory: $worker_dir"
    cp -a "$STS_DIR" "$worker_dir"
done

pids=()
for x in $(seq 1 "$RUNS"); do
    capture_file="$TEST_HW_DIR/$THE_FILE_BASE.$x.bin"

    run_assess "$x" "$capture_file" &
    pids+=("$!")
done

failed=0
for pid in "${pids[@]}"; do
    if ! wait "$pid"; then
        failed=1
    fi
done

# Redisplay final result
for report in "$RESULTS_PARENT_DIR"/AlgorithmTesting.*/finalAnalysisReport.txt; do
    echo
    echo "======================================================================"
    echo "$report"
    echo "======================================================================"
    grep '\*' "$report" || echo "No starred lines"
done

if [ "$failed" -ne 0 ]; then
    echo
    echo "One or more STS runs failed."
    exit 1
fi

echo
echo "done"
