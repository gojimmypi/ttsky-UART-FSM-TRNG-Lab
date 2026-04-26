# Hardware Testing

This directory contains supplementary files for testing the Tiny Tapeout project on hardware, 
specifically the ULX3S FPGA board.

## Files

 - `test-hw\README.md`
 - `test-hw\run_tests.sh`
 - `test-hw\tt_ulx3s_uart_test.py`

## ULX3S

Run tests with `run_tests.sh`:

```
Usage: ./run_tests.sh [--loopback] [--deep-loopback]
          [--ignore-combinational-warning] [--no-warning-pause]

  --loopback: Enable basic loopback mode for build
  --deep-loopback: Enable deeper loopback mode for build
  --ignore-combinational-warning: Ignore ABC combinational network warning (not recommended)
  --no-warning-pause: Do not pause for warnings
```

Examples:

Test with loopback:

```
./run_tests.sh --with-build --loopback
```

Test with deep loopback:

```
./run_tests.sh --with-build --deep-loopback
```

Full build, ignore combinational warning, and no pause on warnings:

```
./run_tests.sh --with-build --ignore-combinational-warning --no-warning-pause
```
