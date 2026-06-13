#!/bin/bash
#
# Copyright (c) 2026 gojimmypi
# SPDX-License-Identifier: Apache-2.0
#
# file: ice40/run_tests.sh
#

echo "**************************************************************************"
echo "**  Begin ${BASH_SOURCE[0]} from ${PWD}"
echo "**************************************************************************"

# Run shellcheck to ensure this is a good script.
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
echo " Setup environment"
echo "**************************************************************************"
. ./env_ice40.sh


# Build
echo "Change to parent directory:"
pushd ../   || exit 1

# tt_tool.py not working locally
#
# yes, there's an inconsistency between `tt_tool.py --harden` and `tt_fpga.py harden`
#

#echo "**************************************************************************"
#echo "Running ${TT_TOOLS}/tt_tool.py harden from $(pwd)"
#echo "**************************************************************************"
#"$TT_TOOLS"/tt_tool.py --harden || exit 1

echo "**************************************************************************"
echo "Running ${TT_TOOLS}/tt_fpga.py harden from $(pwd)"
echo "**************************************************************************"
"$TT_TOOLS"/tt_fpga.py harden || exit 1

echo "**************************************************************************"
echo "Build complete, proceeding to flash..."
echo "**************************************************************************"

# Flash
"$TT_TOOLS/tt_fpga.py" configure --port /dev/ttyS6 --upload --name "$TT_TOP_NAME" --set-default

popd        || exit 1

