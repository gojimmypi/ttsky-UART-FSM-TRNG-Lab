# ULX3S FPGA Wrapper for Tiny Tapeout

This directory includes a [top_ulx3s.v wrapper](./top_ulx3s.v) for testing the TT project on the [ULX3S FPGA board](https://www.crowdsupply.com/radiona/ulx3s). 

See the separate [../test](../test) directory for testing native Tiny Tapeout.

## Files

 - `ulx3s\fujprog-v48-win64.exe`
 - `ulx3s\Makefile`
 - `ulx3s\project.json`
 - `ulx3s\top_ulx3s.v`
 - `ulx3s\ulx3s.bit`
 - `ulx3s\ulx3s_empty.config`
 - `ulx3s\ulx3s_out.config`
 - `ulx3s\ulx3s_v20.lpf`
 - `ulx3s\verilator_lint.sh`

Included are scripts to build the project for the ULX3S and flash it to the board:

- `ulx3s_build.sh` for your basic build.
- `ulx3s_flash.sh` for programming the board from WSL. (a pre-compiled `fujprog-v48-win64.exe` is included)

## Optional Debugging

- `./ulx3s_build.sh --loopback` basic loopback test, which should work on the first try.
- `./ulx3s_build.sh --deep-loopback` a more complex FSM loopback test, which may require some debugging.

## Build Tools

Windows users have a pre-compiled `fujprog-v48-win64.exe` included for programming the board from WSL. Linux users can build `fujprog` from source.

See

- <https://github.com/kost/fujprog>

### Prog

```
./ulx3s_build.sh --loopback --ignore-combinational-warning --no-warning-pause
./ulx3s_build.sh --deep-loopback --ignore-combinational-warning --no-warning-pause
./ulx3s_flash.sh
./ulx3s_flash.sh ../test-hw/tt_um_fpga_ecp5_85k.bit
```

### Test

Note the `--port` argument to specify the serial port for the test script. This should match the port used in your terminal session (e.g., `putty` or `minicom`) to view the output of the FSM and TRNG. 

The `--port` here is the external,stand-alone UART device connected to the ULX3S FPGA pins, not to be confused with the ESP32 FTDI programming serial port built into the ULX3S board.

```
./run_tests.sh --with-build --ignore-combinational-warning --no-warning-pause --port /dev/ttyS11
```

As a reminder: when configured properly, the ULX3S FPGA JTAG programming port does NOT appear as a serial device.

In Windows device manager, select `View` -> `Devices by connection` and expand:

```
ACPI x64-based PC
  -> Microsoft ACPI-Compliant System
    -> PCI Express Root Complex
      -> USB xHCI Host Controller
        -> USB Root Hub
          -> USB Composite Device
```

The ULX3S and UART should appear something like this:

![windows-device-manager-ports.png](../docs/windows-device-manager-ports.png)

## GTK Wave

X-Windows on WSL1

```
startxwin -- -listen tcp -ac
```

Output:

```text
Welcome to the XWin X Server
Vendor: The Cygwin/X Project
Release: 1.21.1.15
OS: CYGWIN_NT-10.0-26200 Notebook70 3.6.5-1.x86_64 2025-10-09 17:21 UTC x86_64
OS: Windows 10  [Windows NT 10.0 build 26200] x64
Package: version 21.1.15-1 built 2025-01-26

XWin was started with the following command line:

/usr/bin/XWin :0 -multiwindow -listen tcp -ac -auth
```

Launch

```bash
rm -f tb tb.vcd
iverilog -o tb tb.v ../src/*.v
vvp tb
gtkwave tb.vcd
```

## Troubleshooting

Some suggestions for success

- Use short, quality USB cables.
- Ensure no terminal sessions are connected to ports when attempting to program.


### Error Messages


#### FT_Open() failed Cannot find JTAG cable

Is there something else connected to the serial port, perhaps a putty session?

```
ULX2S / ULX3S JTAG programmer v4.8 (git 96ebb45 built Oct  7 2020 22:42:00)
Copyright (C) Marko Zec, EMARD, gojimmypi, kost and contributors
FT_Open() failed
Cannot find JTAG cable.
```

#### 
If the ESP32 is running and spewing data to the SPI, UART, etc, consider pressing `rst` (`btn[0]`) to pause and quiet the 
ESP32 in bootloader mode. Otherwise this error may be encountered:

```
Found unknown (FFFFFFFF) device, but the bitstream is for LFE5U-85F.

Failed.
```