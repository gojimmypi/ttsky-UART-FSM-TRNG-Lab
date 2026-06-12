# Project Status

<!-- breadcrumb for testing workflows 1.0b, testing end-to-end build, release Version 0.1.7 6/7/2026" -->

Version 0.1.7

## Status

- Not submitted to [ttsky26a](https://app.tinytapeout.com/prepurchase?shuttle=ttsky26a). (full!)
- Not submitted to o [ttsky26b](https://app.tinytapeout.com/prepurchase?shuttle=ttsky26b) (deadline Mon May 18, 2026)
- Submitted to [ttgf26a](https://app.tinytapeout.com/prepurchase?shuttle=ttgf26a) (deadline Mon June 22, 2026). See [projects #4337](https://app.tinytapeout.com/projects/4337)
- Planning comparative submission to [ttsky26c](https://app.tinytapeout.com/prepurchase?shuttle=ttsky26c)

## Implemented

- Functional [UART](./src/UART/)
- Functional FSM 
- Functional SPI; See [ULX3S ESP32 Demo](../ulx3s/ESP32/README.md)
- Untested actual ASIC [TRNG](./src/TRNG/) for SKY130 and GF180, as well as a stub for testing.
- [JTAG WIP](./src/JTAG/)
- [PIN Diagnostics WIP](./src/PINS/)

## TODO

- Final submission version check
- `CLOCK_PERIOD` at 20 or 40 ns? 
- Decide on JTAG state: macro on or off?
- Check For safe JTAG default ui_in[4] = 1 , consider dip switches, tt.ui_in = int(tt.ui_in) | 0x10
- Review IO pin documentation vs code
- Check for stray TODO text
- sample scripts should have generic `PROJECT` variable instead of hardcoding `ttsky-UART-FSM-TRNG-Lab`.
- Remove ttsy references from ttgf project.
- Test JTAG on hardware. See [ULX3S ESP32 Demo](../ulx3s/ESP32/README.md) for SPI testing on ULX3S.
- Revisit https://github.com/TinyTapeout/ttsky-verilog-template/issues/22
- https://github.com/TinyTapeout/tt-support-tools/pull/167
- https://github.com/TinyTapeout/tt-gds-action/pull/47
- https://github.com/TinyTapeout/ttsky-verilog-template/pull/23
- https://github.com/TinyTapeout/ttsky-verilog-template/pull/25
- https://github.com/TinyTapeout/tinytapeout_www/pull/229
- https://github.com/TinyTapeout/tinytapeout_www/pull/230
- https://github.com/TinyTapeout/tinytapeout_www/pull/231
- Create timeout PR. See https://github.com/gojimmypi/ttsky-UART-FSM-TRNG-Lab/actions/runs/27152683035
- Create Demoboard script examples. See https://discord.com/channels/1009193568256135208/1011201396659474432/1512868833503875093
- Address my 60C/85C feature request https://github.com/TinyTapeout/tt-gds-action/issues/49
