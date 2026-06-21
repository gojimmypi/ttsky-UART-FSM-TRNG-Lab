#!/bin/bash
#
# Copyright (c) 2026 gojimmypi
# SPDX-License-Identifier: Apache-2.0
#
# file: scripts/clean_files.sh
#
# Extract VERSION_STRING from a Verilog project_config.v file.
#
# Example:
#   EXPECTED_VERSION="$(./get_expected_version.sh src/project_config.v)"
#
# Expected Verilog line:
#   `define VERSION_STRING "Version 1.0.2 6/16/2026"
#

set -euo pipefail

CONFIG_FILE="${1:-../src/project_config.v}"
VERSION_DEFINE="VERSION_STRING"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file not found: $CONFIG_FILE" >&2
    exit 1
fi

# Step 1: Find the line that defines VERSION_STRING.
VERSION_LINE="$(
    grep -E "^[[:space:]]*\`define[[:space:]]+${VERSION_DEFINE}[[:space:]]+\"" "$CONFIG_FILE" |
    head -n 1 ||
    true
)"

if [ -z "$VERSION_LINE" ]; then
    echo "ERROR: ${VERSION_DEFINE} not found in $CONFIG_FILE" >&2
    exit 1
fi

# Step 2: Extract the text inside the first pair of double quotes.
EXPECTED_VERSION="$(
    printf '%s\n' "$VERSION_LINE" |
    sed -E "s/^[[:space:]]*\`define[[:space:]]+${VERSION_DEFINE}[[:space:]]+\"([^\"]*)\".*/\1/"
)"

if [ -z "$EXPECTED_VERSION" ] || [ "$EXPECTED_VERSION" = "$VERSION_LINE" ]; then
    echo "ERROR: Could not extract quoted version from line:" >&2
    echo "  $VERSION_LINE" >&2
    exit 1
fi

# Step 3: Print only the extracted value.
# This keeps the script easy to use with command substitution.
printf '%s\n' "$EXPECTED_VERSION"
