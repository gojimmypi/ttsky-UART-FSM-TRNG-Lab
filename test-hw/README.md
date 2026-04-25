# Hardware Testing

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
