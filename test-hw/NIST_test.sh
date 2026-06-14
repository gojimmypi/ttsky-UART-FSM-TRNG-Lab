#!/bin/bash
#
# Copyright (c) 2026 gojimmypi
# SPDX-License-Identifier: Apache-2.0
#
# This error:
#
#   warning: capture attempt 1 failed: timeout after 228 of 255 bytes after 4 read timeouts
#
# May be USB/TTY related. See https://x.com/pocketmt/status/2061909268840780270?s=20
# > Be careful with the usb to uart adapter you are using on this photo 
#   (at left). For high speed uart when you do full duplex com with it, 
#   on large packets it may lose packets. I discovered it when I was using 
#   it at 3V3 with RP2040 trying different configurations of the Uart api.


DEFAULT_FILE_BASE="trng_conditioned_2MiB"
PORT="${PORT:-/dev/ttyS12}"
BYTES=2097152
BITS_PER_STREAM=1048576
RUNS=2
STREAMS_PER_RUN=16
USE_FAST_BAUD="${USE_FAST_BAUD:-1}"
CAPTURE_PROGRESS="${CAPTURE_PROGRESS:-1}"
CAPTURE_PROGRESS_INTERVAL="${CAPTURE_PROGRESS_INTERVAL:-5}"
VERBOSE_CLEANUP="${VERBOSE_CLEANUP:-1}"

set -euo pipefail

usage() {
    cat <<EOF_USAGE
Usage:
  $0 [capture_output_base]

Examples:
  $0
  $0 trng_conditioned_2MiB
  USE_FAST_BAUD=0 $0 trng_conditioned_2MiB
  CAPTURE_PROGRESS=1 $0 trng_conditioned_2MiB
  VERBOSE_CLEANUP=1 $0 trng_conditioned_2MiB

Arguments:
  capture_output_base
      Optional base name for NEW captured TRNG files.
      Default: trng_conditioned_2MiB

      This is not an existing input file to test. The script always captures
      new files before running STS.

      Output files are:
          <capture_output_base>.1.bin
          <capture_output_base>.2.bin
Environment:
  PORT
      UART port to use.
      Default: /dev/ttyS12

  USE_FAST_BAUD
      Set to 0 to remove --fast-baud from capture_trng_raw_uart.py.
      Default: 1

  CAPTURE_PROGRESS
      Set to 1 to pass --progress to capture_trng_raw_uart.py.
      Default: 1

  CAPTURE_PROGRESS_INTERVAL
      Progress update interval in seconds when CAPTURE_PROGRESS=1.
      Positive integer only.
      Default: 5

  VERBOSE_CLEANUP
      Set to 1 to show before/after STS cleanup directory counts.
      Default: 1
EOF_USAGE
} # usage()

if [ "$#" -gt 1 ]; then
    usage
    exit 2
fi

case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
    --\?)
        usage
        exit 0
        ;;
esac

THE_FILE_BASE="${1:-$DEFAULT_FILE_BASE}"

case "$THE_FILE_BASE" in
    *.bin)
        echo "ERROR: argument is an output base name, not an existing .bin file."
        echo "       Use a base name such as: ${THE_FILE_BASE%.bin}"
        echo "       This script will create: ${THE_FILE_BASE%.bin}.1.bin and ${THE_FILE_BASE%.bin}.2.bin"
        exit 2
        ;;
esac

if [ -z "$THE_FILE_BASE" ]; then
    echo "ERROR: capture_output_base must not be empty."
    exit 2
fi

case "$USE_FAST_BAUD" in
    0|1)
        ;;
    *)
        echo "ERROR: USE_FAST_BAUD must be 0 or 1."
        exit 2
        ;;
esac

case "$CAPTURE_PROGRESS" in
    0|1)
        ;;
    *)
        echo "ERROR: CAPTURE_PROGRESS must be 0 or 1."
        exit 2
        ;;
esac

case "$VERBOSE_CLEANUP" in
    0|1)
        ;;
    *)
        echo "ERROR: VERBOSE_CLEANUP must be 0 or 1."
        exit 2
        ;;
esac

case "$CAPTURE_PROGRESS_INTERVAL" in
    ''|*[!0-9]*)
        echo "ERROR: CAPTURE_PROGRESS_INTERVAL must be a positive integer."
        exit 2
        ;;
esac

if [ "$CAPTURE_PROGRESS_INTERVAL" -le 0 ]; then
    echo "ERROR: CAPTURE_PROGRESS_INTERVAL must be greater than 0."
    exit 2
fi

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

TEST_HW_DIR="$(pwd)"
STS_DIR="$(cd ../../sts-2.1.2 && pwd)"
RESULTS_PARENT_DIR="$(cd "$STS_DIR/experiments" && pwd)"
RESULTS_DIR="$RESULTS_PARENT_DIR/AlgorithmTesting"
WORK_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/nist_sts_parallel.XXXXXXXXXX")"

cleanup() {
    rm -rf -- "$WORK_ROOT"
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

safe_rm_run_results_dir() {
    local dir="$1"
    local base
    local parent
    local suffix

    if [ -z "$dir" ]; then
        echo "ERROR: refusing to remove empty path"
        exit 1
    fi

    base="$(basename "$dir")"
    parent="$(cd "$(dirname "$dir")" && pwd)"

    if [ "$parent" != "$RESULTS_PARENT_DIR" ]; then
        echo "ERROR: refusing to remove path outside results parent: $dir"
        echo "Expected parent: $RESULTS_PARENT_DIR"
        echo "Actual parent:   $parent"
        exit 1
    fi

    case "$base" in
        AlgorithmTesting.*)
            ;;
        *)
            echo "ERROR: refusing to remove unexpected results directory: $dir"
            exit 1
            ;;
    esac

    suffix="${base#AlgorithmTesting.}"

    case "$suffix" in
        ''|*[!0-9]*)
            echo "ERROR: refusing to remove unexpected results directory: $dir"
            exit 1
            ;;
    esac

    case "$dir" in
        /|/tmp|/tmp/|/mnt|/mnt/|/mnt/c|/mnt/c/|"$RESULTS_PARENT_DIR")
            echo "ERROR: refusing to remove unsafe path: $dir"
            exit 1
            ;;
    esac

    rm -rf -- "$dir"
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

    echo "Resetting STS results for run $x"

    if [ "$VERBOSE_CLEANUP" -eq 1 ]; then
        echo "Before rm -rf $run_results_dir:"
        list_results_dir "$run_results_dir"
    fi

    safe_rm_run_results_dir "$run_results_dir"

    if [ "$VERBOSE_CLEANUP" -eq 1 ]; then
        echo "After rm -rf $run_results_dir:"
        list_results_dir "$run_results_dir"

        echo "Before reset_results_dir $worker_results_dir:"
        list_results_dir "$worker_results_dir"
    fi

    reset_results_dir "$worker_results_dir"

    if [ "$VERBOSE_CLEANUP" -eq 1 ]; then
        echo "After reset_results_dir $worker_results_dir:"
        list_results_dir "$worker_results_dir"
    fi

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
} # run_assess()

capture_args=(--port "$PORT" --bytes "$BYTES" --conditioned)

if [ "$USE_FAST_BAUD" -eq 1 ]; then
    capture_args+=(--fast-baud)
fi

if [ "$CAPTURE_PROGRESS" -eq 1 ]; then
    capture_args+=(--progress --progress-interval "$CAPTURE_PROGRESS_INTERVAL")
fi

echo "Capture file base: $THE_FILE_BASE"
echo "Default file base: $DEFAULT_FILE_BASE"
echo "Port: $PORT"
echo "Bytes per capture: $BYTES"
echo "Runs: $RUNS"
echo "Bits per stream: $BITS_PER_STREAM"
echo "Streams per run: $STREAMS_PER_RUN"
echo "Fast baud: $USE_FAST_BAUD"
echo "Capture progress: $CAPTURE_PROGRESS"
if [ "$CAPTURE_PROGRESS" -eq 1 ]; then
    echo "Capture progress interval: $CAPTURE_PROGRESS_INTERVAL"
fi
echo "Verbose cleanup: $VERBOSE_CLEANUP"
echo

./show_effective_defines.sh

for x in $(seq 1 "$RUNS"); do
    capture_file="$TEST_HW_DIR/$THE_FILE_BASE.$x.bin"

    echo
    echo "======================================================================"
    echo "Capture $x of $RUNS"
    echo "======================================================================"

    cd "$TEST_HW_DIR"

    if [ "$USE_FAST_BAUD" -eq 1 ]; then
        echo "Capturing $BYTES bytes to $capture_file from $PORT (fast baud, conditioned)"
    else
        echo "Capturing $BYTES bytes to $capture_file from $PORT (default baud, conditioned)"
    fi

    ./capture_trng_raw_uart.py \
        "${capture_args[@]}" \
        --out "$capture_file"

    # Sanity check on the file just captured.
    python3 - "$capture_file" <<'EOF_PYTHON'
import math
import sys
from collections import Counter

path = sys.argv[1]

with open(path, "rb") as f:
    data = f.read()

if not data:
    print(f"Capture sanity: {path}")
    print("  bytes: 0")
    print("  ERROR: captured file is empty")
    sys.exit(1)

ones = sum(byte.bit_count() for byte in data)
bits = len(data) * 8
counts = Counter(data)
entropy = -sum((n / len(data)) * math.log2(n / len(data)) for n in counts.values())

print(f"Capture sanity: {path}")
print(f"  bytes: {len(data)}")
print(f"  one_ratio: {ones / bits:.9f}")
print(f"  unique_byte_values: {len(counts)}")
print(f"  byte_entropy: {entropy:.6f} bits/byte")
EOF_PYTHON

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
