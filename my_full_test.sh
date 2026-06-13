#!/bin/bash
#
# Copyright (c) 2026 gojimmypi
# SPDX-License-Identifier: Apache-2.0
#
# file: my_full_test.sh
#

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

pushd test || exit 1

./my_test.sh

popd || exit 1

pushd ice40 || exit 1

. ./env_ice40.sh
./build_and_flash.sh
./project_reset.sh
./run_tests.sh

popd || exit 1

