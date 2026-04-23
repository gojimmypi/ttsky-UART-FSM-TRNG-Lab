#!/bin/bash
#
# ./build.sh
# ./build.sh --loopback

# Default: no loopback
MAKE_ARGS=""

for arg in "$@"; do
    if [ "$arg" = "--loopback" ]; then
        echo "Enabling loopback mode for build"
        MAKE_ARGS="$MAKE_ARGS FORCE_LOOPBACK=1"
    fi
done

make clean

make $MAKE_ARGS 2>&1 | tee error.log

grep -i error error.log

for arg in "$@"; do
    if [ "$arg" = "--loopback" ]; then
        echo "Reminder: Enabling loopback mode for build"
    fi
done