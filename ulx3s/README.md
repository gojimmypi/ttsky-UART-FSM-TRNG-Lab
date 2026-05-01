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


## Troubleshooting

Some suggestions for success

- Use short, quality USB cables.
- Ensure no terminal sessions are connected to ports when attempting to program.


### Error Messages

If the ESP32 is running and spewing data to the SPI, UART, etc, consider pressing `rst` (`btn[0]`) to pause and quiet the 
ESP32 in bootloader mode. Otherwise this error may be encountered:

```
Found unknown (FFFFFFFF) device, but the bitstream is for LFE5U-85F.

Failed.
```