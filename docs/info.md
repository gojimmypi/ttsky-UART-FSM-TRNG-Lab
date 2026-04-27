<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->


## How it works

TODO: Add a detailed description of how the FSM and TRNG work, including any relevant diagrams or flowcharts.

### UART

Connect with your favorite terminal program such as putty.

For the ULX3S FPGA, the UART is connected to pins XX and YY The default baud rate is 115200.

See the [default reference ULX3S ulx3s_v20.lpf restraint file](https://github.com/emard/ulx3s/blob/master/doc/constraints/ulx3s_v20.lpf).

Disabled:

```
# FREQUENCY PORT "gn[12]" 50 MHZ;
# FREQUENCY PORT "gn12" 50 MHZ;
```

Previously:

The `B11` and `A10` pins were updated with new names:

```
LOCATE COMP "gp[0]" SITE "B11"; # J1_5+  GP0 PCLK
LOCATE COMP "gp[1]" SITE "A10"; # J1_7+  GP1 PCLK
```

These

```
# UART pins for testing

LOCATE COMP "uart_rx_pin" SITE "B11"; # formerly "gp[0]"; # J1_5+  GP0 PCLK
IOBUF PORT "uart_rx_pin" IO_TYPE=LVCMOS33;

LOCATE COMP "uart_tx_pin" SITE "A10"; # formerly "gp[1]"; # J1_7+  GP1 PCLK
IOBUF PORT "uart_tx_pin" IO_TYPE=LVCMOS33;
```

## How to test

There are TT simulation tests and local ULX3S FPGA tests.

### TT Simulation tests

Commit changes. See results in [actions](./actions/).

In particular, note the output of the [gds workflow](./actions/workflows/gds.yaml):

- Linter output
- Routing Stats
- Cell usage by Category
- Tiny Tapeout Precheck Results
- Viewer summary


### Test on ULX3S FPGA

Build and flash the bitstream to the FPGA, then run the test script. The test script will print the output of the FSM and TRNG.

Test locally with ULX3S FPGA in [/ulx3s/](../ulx3s/README.md) directory.

- [verilator_lint.sh](../ulx3s/verilator_lint.sh)
- [ulx3s_build.sh](../ulx3s/ulx3s_build.sh)
- [ulx3s_flash.sh](../ulx3s/ulx3s_flash.sh)

Example:

```bash
cd uls3s

./ulx3s_build.sh
./ulx3s_flash.sh
```

Connect to the FPGA using a serial terminal (e.g., `putty` or `minicom`) to view the output of the FSM and TRNG.

### Local Loopback Test

There are two loopback tests: a basic loopback test and a deep loopback test. The basic loopback test verifies that the UART is functioning 
correctly by sending data from the FPGA to the host and back. The deep loopback test verifies that the FSM and TRNG are functioning correctly 
by sending commands to the FPGA and reading the responses.

#### Basic Loopback Test

The basic loopback assigns `Tx` to `Rx` in `top_ulx3s.v`.

```verilog
    assign uart_tx_pin = uart_rx_sync;
```

All characters should be echoed back in the terminal when you type. This verifies that the UART is working correctly.

Sample loopback build defines `FORCE_LOOPBACK=1` macro in `ulx3s_build.sh`:

```bash
./ulx3s_build.sh --loopback --ignore-combinational-warning --no-warning-pause
./ulx3s_flash.sh
```

### Deep Loopback Test

```bash
./ulx3s_build.sh --deep-loopback --ignore-combinational-warning --no-warning-pause
./ulx3s_flash.sh
```

### Local Automated Hardware Operation Tests

Generic local hardware operation tests in [/test-hw/](../test-hw/README.md).

- [tt_ulx3s_uart_test.py](../test-hw/tt_ulx3s_uart_test.py) - Python script to test the UART functionality of the FSM and TRNG on the ULX3S FPGA. It sends commands to the FPGA and reads the responses to verify correct operation.
- [run_tests.sh](../test-hw/run_tests.sh) - Shell script to run the hardware tests. It can be configured to build the FPGA bitstream, flash it to the FPGA, and run the Python test script.

```bash
cd test-hw

 ./run_tests.sh --with-build --ignore-combinational-warning --no-warning-pause
```



## External hardware

So far, none.
