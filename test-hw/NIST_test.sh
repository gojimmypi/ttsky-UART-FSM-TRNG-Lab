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
RUNS=2

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

list_results_dir() {
    local dir="$1"
    local count

    if [ -d "$dir" ]; then
        count="$(find "$dir" -type f | wc -l)"
        echo "$dir: $count files"
    else
        echo "$dir: does not exist"
    fi
}

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

make_worker_dir() {
    local worker_dir="$1"
    local entry
    local base

    mkdir -p "$worker_dir"

    for entry in "$STS_DIR"/* "$STS_DIR"/.[!.]* "$STS_DIR"/..?*; do
        if [ ! -e "$entry" ]; then
            continue
        fi

        base="$(basename "$entry")"

        case "$base" in
            .|..|.vs|experiments)
                continue
                ;;
        esac

        ln -s "$entry" "$worker_dir/$base"
    done

    mkdir -p "$worker_dir/experiments"
    cp -a "$RESULTS_DIR" "$worker_dir/experiments/AlgorithmTesting"
}

run_assess() {
    local x="$1"
    local capture_file="$2"
    local worker_dir="$WORK_ROOT/sts-2.1.2.$x"
    local worker_results_dir="$worker_dir/experiments/AlgorithmTesting"
    local run_results_dir="$RESULTS_PARENT_DIR/AlgorithmTesting.$x"
    local run_report="$run_results_dir/finalAnalysisReport.txt"
    local assess_rc

    echo
    echo "======================================================================"
    echo "STS run $x of $RUNS"
    echo "======================================================================"

    make_worker_dir "$worker_dir"

    cd "$worker_dir"

    echo "Deleting old saved STS results directory for run $x"
    echo "Before rm -rf $run_results_dir:"
    list_results_dir "$run_results_dir"
    rm -rf "$run_results_dir"
    echo "After rm -rf $run_results_dir:"
    list_results_dir "$run_results_dir"

    echo "Initializing worker STS results directory for run $x"
    echo "Before reset_results_dir $worker_results_dir:"
    list_results_dir "$worker_results_dir"
    reset_results_dir "$worker_results_dir"
    echo "After reset_results_dir $worker_results_dir:"
    list_results_dir "$worker_results_dir"

    echo "Checking file $capture_file"

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

    cp -a "$worker_results_dir" "$run_results_dir"

    echo "Saved full results directory: $run_results_dir"

    echo
    echo "Starred STS results for run $x:"
    if [ -f "$run_report" ]; then
        grep '\*' "$run_report" || echo "No starred lines"
    else
        echo "WARNING: no finalAnalysisReport.txt found in $run_results_dir"
    fi

    return "$assess_rc"
} # Run assess

./show_effective_defines.sh

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
