# ULX3S FPGA Wrapper for Tiny Tapeout

This directory includes a [top_ulx3s.v wrapper](./top_ulx3s.v) for testing the TT project on the [ULX3S FPGA board](https://www.crowdsupply.com/radiona/ulx3s). 

See the separate [../test](../test) directory for testing native Tiny Tapeout.

Included are scripts to build the project for the ULX3S and flash it to the board:

- `ulx3s_build.sh` for your basic build.
- `ulx3s_wsl_prog.sh` for programming the board from WSL. (a pre-compiled `fujprog-v48-win64.exe` is included)
