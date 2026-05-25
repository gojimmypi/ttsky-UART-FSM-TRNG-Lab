# Hardware Testing

This directory contains supplementary files for testing the Tiny Tapeout project on hardware, 
specifically the ULX3S FPGA board.

## Files

 - `test-hw\README.md`
 - `test-hw\run_tests.sh`
 - `test-hw\tt_ulx3s_uart_test.py`

## ULX3S

Run tests with `run_tests.sh`:

```text
Usage: ./run_tests.sh [--with-build] [--loopback] [--deep-loopback]
          [--ignore-combinational-warning] [--no-warning-pause]
          [--ulx3s-board-version <version>] [--ulx3s-board-version=<version>]
          [--board-version <version>] [--board-version=<version>]
          [--port <port>]
          [--pause-for-test]

  --with-build: Build and flash before running tests
  --loopback: Enable basic loopback mode for build
  --deep-loopback: Enable deeper loopback mode for build
  --ignore-combinational-warning: Ignore ABC combinational network warning
  --no-warning-pause: Do not pause for warnings
  --ulx3s-board-version <version>: Select ULX3S board version for build
  --ulx3s-board-version=<version>: Select ULX3S board version for build
  --board-version <version>: Alias for --ulx3s-board-version
  --board-version=<version>: Alias for --ulx3s-board-version
  --port <port>: Serial port to use for tests
  --pause-for-test: Pause before tests to allow setup
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

Check ESP32 UART

If there's a running ESP32 program without serial output, show some lines of text:

```
 ./ulx3s_esp32_uart_test.py --port /dev/ttyS3 --lines 10 --timeout 20
```


## Troubleshooting

For `could not open port /dev/ttyS11` such as that shown below, make sure the port is not already in use by another program, such as a terminal program or another instance of the test script. 

If the port number has changed, which is common with Windows, pass the correct port number to the test script using the `--port` argument, for example: 

```
python ./tt_ulx3s_uart_test.py --port /dev/ttyS3
```

Or edit the default port in `run_tests.sh`

```text
ULX2S / ULX3S JTAG programmer v4.8 (git 96ebb45 built Oct  7 2020 22:42:00)
Copyright (C) Marko Zec, EMARD, gojimmypi, kost and contributors
Using USB cable: ULX3S FPGA 12K v3.0.3
Programming: 100%
Completed in 12.98 seconds.
/mnt/c/workspace/ttsky-UART-FSM-TRNG-Lab/test-hw
Traceback (most recent call last):
  File "/home/gojimmypi/.local/lib/python3.10/site-packages/serial/serialposix.py", line 322, in open
    self.fd = os.open(self.portstr, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
OSError: [Errno 5] Input/output error: '/dev/ttyS11'

During handling of the above exception, another exception occurred:

Traceback (most recent call last):
  File "/mnt/c/workspace/ttsky-UART-FSM-TRNG-Lab/test-hw/./tt_ulx3s_uart_test.py", line 397, in <module>
    sys.exit(main())
  File "/mnt/c/workspace/ttsky-UART-FSM-TRNG-Lab/test-hw/./tt_ulx3s_uart_test.py", line 375, in main
    ser = serial.Serial(args.port, args.baud, timeout=0.01)
  File "/home/gojimmypi/.local/lib/python3.10/site-packages/serial/serialutil.py", line 244, in __init__
    self.open()
  File "/home/gojimmypi/.local/lib/python3.10/site-packages/serial/serialposix.py", line 325, in open
    raise SerialException(msg.errno, "could not open port {}: {}".format(self._port, msg))
serial.serialutil.SerialException: [Errno 5] could not open port /dev/ttyS11: [Errno 5] Input/output error: '/dev/ttyS11'
```
