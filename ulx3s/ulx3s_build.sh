#!/bin/bash
#
# ./ulx3s_build.sh
# ./ulx3s_build.sh --loopback
# ./ulx3s_build.sh --deep-loopback

# Default: no loopback
MAKE_ARGS=""
FOUND_KNOWN_ARG=0

for arg in "$@"; do
    # A basic loopback that tests high level tx/rx communication
    if [ "$arg" = "--loopback" ]; then
        FOUND_KNOWN_ARG=1
        echo "Enabling loopback mode for build"
        MAKE_ARGS="$MAKE_ARGS FORCE_LOOPBACK=1"
    fi

    # A deeper and more complex logic loopback that tests more of the internal logic and is more likely to catch issues
    if [ "$arg" = "--deep-loopback" ]; then
        FOUND_KNOWN_ARG=1
        echo "Enabling deep loopback mode for build"
        MAKE_ARGS="$MAKE_ARGS FORCE_DEEP_LOOPBACK=1"
    fi

    if [ "$FOUND_KNOWN_ARG" -eq 0 ]; then
        echo "Unknown argument: $arg"
        exit 1
    fi

    if [ "$FOUND_KNOWN_ARG" -eq 0 ]; then 
        echo "Usage: $0 [--loopback] [--deep-loopback]"
        echo "  --loopback: Enable basic loopback mode for build"
        echo "  --deep-loopback: Enable deeper loopback mode for build"
        exit 1
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