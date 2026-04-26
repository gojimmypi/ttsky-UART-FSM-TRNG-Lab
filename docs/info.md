<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->


## How it works

TODO: Add a detailed description of how the FSM and TRNG work, including any relevant diagrams or flowcharts.

## How to test

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

### Local Hardware Operation Tests

Generic local hardware operation tests in [/test-hw/](../test-hw/README.md).

- [tt_ulx3s_uart_test.py](../test-hw/tt_ulx3s_uart_test.py) - Python script to test the UART functionality of the FSM and TRNG on the ULX3S FPGA. It sends commands to the FPGA and reads the responses to verify correct operation.
- [run_tests.sh](../test-hw/run_tests.sh) - Shell script to run the hardware tests. It can be configured to build the FPGA bitstream, flash it to the FPGA, and run the Python test script.

```bash
cd test-hw

 ./run_tests.sh --with-build --ignore-combinational-warning --no-warning-pause
```



## External hardware

So far, none.
