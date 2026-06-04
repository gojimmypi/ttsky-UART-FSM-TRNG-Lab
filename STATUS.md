# Project Status

<!-- breadcrumb for testing workflows 1.0b, testing end-to-end build, release v0.1.5d -->

## Status

- Not submitted to [ttsky26a](https://app.tinytapeout.com/prepurchase?shuttle=ttsky26a). (full!)
- Not submitted to o [ttsky26b](https://app.tinytapeout.com/prepurchase?shuttle=ttsky26b) (deadline Mon May 18, 2026)
- Submitted to [ttgf26a](https://app.tinytapeout.com/prepurchase?shuttle=ttgf26a) (deadline Mon June 22, 2026). See [projects #4337](https://app.tinytapeout.com/projects/4337)
- Planning comparative submission to [ttsky26c](https://app.tinytapeout.com/prepurchase?shuttle=ttsky26c)

Version 0.1.5d

## Implemented

- Functional [UART](./src/UART/)
- Functional FSM 
- Functional SPI; See [ULX3S ESP32 Demo](../ulx3s/ESP32/README.md)
- Untested actual ASIC [TRNG](./src/TRNG/) for SKY130 and GF180, as well as a stub for testing.
- [JTAG WIP](./src/JTAG/)

## TODO

- sample scripts should have generic `PROJECT` variable instead of hardcoding `ttsky-UART-FSM-TRNG-Lab`.
- Remove ttsy references from ttgf project.
- Test JTAG on hardware. See [ULX3S ESP32 Demo](../ulx3s/ESP32/README.md) for SPI testing on ULX3S.
