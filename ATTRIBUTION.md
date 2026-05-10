# ATTRIBUTION

This project builds upon open-source tools, templates, and publicly available reference designs.  
The author gratefully acknowledges the following sources.

---

## TinyTapeout Templates

This project is derived from TinyTapeout reference templates:

- https://github.com/TinyTapeout/ttsky-analog-template
- https://github.com/TinyTapeout/ttsky-verilog-template

These templates define the standard TinyTapeout interface, project structure, and CI flow.

---

## UART Reference Implementations

The UART finite state machine (FSM) design follows standard UART
implementation patterns (start bit, data bits, stop bit sequencing)
commonly used in FPGA designs.

The minimal UART RX and TX modules in this repository are original implementations
inspired by common FPGA UART examples, including:

- https://nandland.com/uart-serial-port-module/

These modules were adapted and rewritten for this project.

---

## EMARD

Numerous design, implementation, and other references created by EMARD:

- https://github.com/emard/ulx3s
- https://github.com/emard/ulx3s-misc
- https://github.com/emard/esp32ecp5

## ULX3S Platform Resources

Development and testing were performed using the ULX3S FPGA platform.
Relevant resources include:

- https://ulx3s.github.io/
- https://github.com/emard/ulx3s

---

## Testbench and Simulation

Testbench structure and simulation flow are based on standard Verilog and cocotb practices,
with influence from TinyTapeout examples and general open-source resources.

---

## Tools and Assistance

Development of this project included the use of automated code analysis and review tools,
including AI-assisted tooling, to improve code quality and correctness.

---

## Community Acknowledgment

Thanks to the TinyTapeout community, FPGA developers, and open-source contributors
whose shared knowledge and examples made this project possible.