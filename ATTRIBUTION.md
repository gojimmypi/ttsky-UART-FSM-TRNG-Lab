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

## Goran Mahovlic

Many thanks to my friend Goran who has publicly and privately helped me understand the ULX3S features since 2019.

## Julia Desmazes, see:

Informative blog on JTAG TAP design and implementation:

- https://essenceia.github.io/projects/two_weeks_until_tapeout/#jtag-tap-design

## ULX3S Platform Resources

Development and testing were performed using the ULX3S FPGA platform.
Relevant resources include:

- https://ulx3s.github.io/
- https://github.com/emard/ulx3s
- Discord: https://discord.gg/qwMUk6W (problems/question/general chat)

---

## Testbench and Simulation

Testbench structure and simulation flow are based on standard Verilog and cocotb practices,
with influence from TinyTapeout examples and general open-source resources.

---

## Tools and Assistance

Development of this project included the use of automated code analysis and review tools,
including AI-assisted tooling and image generation, to improve code quality and correctness.

Code was reviewed and refined with the assistance of AI tools, 
but all final code and design decisions were made by the author.

---

## Community Acknowledgment

Thanks to the TinyTapeout community, FPGA developers, and open-source contributors
whose shared knowledge and examples made this project possible.

## All the TT RNG Projects that came before

| Shuttle | Address | Project title | Author | Full link |
|---|---:|---|---|---|
| TT05 | 47 | Intructouction to PRBS | Chih-Kuan Ho and David Parent | https://tinytapeout.com/chips/tt05/tt_um_wokwi_380409904919056385 |
| TT05 | 128 | Count via LFSR | Eric Smith | https://tinytapeout.com/chips/tt05/tt_um_wokwi_379764885531576321 |
| TT05 | 320 | A Boolean function based pseudo random number generator (PRNG) | SEAL, CSE Department, IIT Kharagpur | https://tinytapeout.com/chips/tt05/tt_um_prg |
| TT05 | 330 | Clock and Random Number Gen | Austin Lo | https://tinytapeout.com/chips/tt05/tt_um_clkdiv |
| TT05 | 641 | PRBS Generator | Ivan M Bow | https://tinytapeout.com/chips/tt05/tt_um_wokwi_377426511818305537 |
| TT06 | 160 | 32-Bit Fibonacci Linear Feedback Shift Register | icaris lab | https://tinytapeout.com/chips/tt06/tt_um_wokwi_394704587372210177 |
| TT06 | 228 | 10-bit Linear feedback shift register | Shivam Bhardwaj, Sachin Sharma, Pankaj Lodhi and Ambika Prasad Shah | https://tinytapeout.com/chips/tt06/tt_um_LFSR_shivam |
| TT06 | 294 | 8-bit PRNG | Jakub Duchniewicz | https://tinytapeout.com/chips/tt06/tt_um_jduchniewicz_prng |
| TT06 | 418 | 32-Bit Galois Linear Feedback Shift Register | icaris lab | https://tinytapeout.com/chips/tt06/tt_um_wokwi_394707429798790145 |
| TT06 | 421 | Bivium-B Non-Linear Feedback Shift Register | icaris lab | https://tinytapeout.com/chips/tt06/tt_um_wokwi_395263962779770881 |
| TT06 | 487 | Trivium Non-Linear Feedback Shift Register | icaris lab | https://tinytapeout.com/chips/tt06/tt_um_wokwi_395357890431011841 |
| TT06 | 654 | RNG3 | Luca Collini | https://tinytapeout.com/chips/tt06/tt_um_rng_3_lucaz97 |
| TT06 | 683 | Random number generator | VineetaVNair & ShilpaPavithran | https://tinytapeout.com/chips/tt06/tt_um_rng |
| TT06 | 842 | rng Test | Luca Collini | https://tinytapeout.com/chips/tt06/tt_um_lucaz97_rng_tests |
| TT07 | 194 | 8 bit PRNG | Jorge Garcia Martinez | https://tinytapeout.com/chips/tt07/tt_um_jorga20j_prng |
| TT07 | 206 | LFSR | James Meech and Werner Florian | https://tinytapeout.com/chips/tt07/tt_um_lfsr |
| TT09 | 107 | LFSR Encrypter | Mitchell Tansey | https://tinytapeout.com/chips/tt09/tt_um_LFSR_Encrypt |
| TT09 | 143 | Linear Feedback Shift Register | Steve Jenson | https://tinytapeout.com/chips/tt09/tt_um_lfsr_stevej |
| TT09 | 166 | Multi-LFSR | Kevin W. Rudd | https://tinytapeout.com/chips/tt09/tt_um__kwr_lfsr__top |
| TT09 | 333 | an lfsr with synaptic neurons (excitatory or inhibitatory) | kai juarez-jimenez | https://tinytapeout.com/chips/tt09/tt_um_juarez_jimenez |
| TT09 | 418 | 8 bit LFSR | Aaron Nowack | https://tinytapeout.com/chips/tt09/tt_um_wokwi_414120263584922625 |
| TT09 | 424 | TinyTapeout workshop - Wokwi 8 Bit LFSR | Nate Voorhies | https://tinytapeout.com/chips/tt09/tt_um_wokwi_414121532514097153 |
| TT09 | 450 | Pseudo Random Generator Using 2 Ring Oscillators | Michael Yim | https://tinytapeout.com/chips/tt09/tt_um_wokwi_413387152803294209 |
| TT09 | 553 | rand | mahi | https://tinytapeout.com/chips/tt09/tt_um_wokwi_414120509472942081 |
| TTIHP25a | 75 | LFSR Encrypter | Mitchell Tansey | https://tinytapeout.com/chips/ttihp25a/75 |
| TTIHP25a | 387 | 7-segment with LFSR | Jun-ichi OKAMURA | https://tinytapeout.com/chips/ttihp25a/387 |
| TTIHP25a | 612/0 | Pseudo Random Generator Using 2 Ring Oscillators | Michael Yim | https://tinytapeout.com/chips/ttihp25a/612/0 |
| TTIHP25a | 612/8 | 8 bit LFSR | Aaron Nowack | https://tinytapeout.com/chips/ttihp25a/612/8 |
| TTIHP25a | 612/12 | TinyTapeout workshop - Wokwi 8 Bit LFSR | Nate Voorhies | https://tinytapeout.com/chips/ttihp25a/612/12 |
| TTIHP25a | 746 | TRNG | Muhammad Bilal | https://tinytapeout.com/chips/ttihp25a/tt_um_bilal_trng |
| TTIHP25a | 871 | an lfsr with synaptic neurons (excitatory or inhibitatory) | kai juarez-jimenez | https://tinytapeout.com/chips/ttihp25a/871 |
| TTIHP25a | app project 1937 | RNG_test | — | https://app.tinytapeout.com/projects/1937 |
| TTIHP25b | 128 | RNG | Felix N | https://tinytapeout.com/chips/ttihp25b/tt_um_Xelef2000 |
| TTIHP25b | 166 | Random | vans24 | https://tinytapeout.com/chips/ttihp25b/tt_um_wokwi_434917682511205377 |
| TTIHP26a | — | RandomNum | — | https://tinytapeout.com/chips/ttihp26a/tt_um_wokwi_450492230413445121 |
| TTIHP26a | — | RO-based security primitives | — | https://tinytapeout.com/chips/ttihp26a/tt_um_ro_puf_trng |
| TTIHP26a | 242 | True(er) Random Number Generator (TRNG) | Angelo Nujic | https://tinytapeout.com/chips/ttihp26a/tt_um_anujic_rng |
| TTIHP26a | 561 | VGA multiplex with TRNG | Khanh Lo | https://tinytapeout.com/chips/ttihp26a/tt_um_lkhanh_vga_trng |
| TTIHP26a | 611 | RNG | Felix N | https://tinytapeout.com/chips/ttihp26a/tt_um_Xelef2000 |
| TTIHP26a | 684 | 8-bit PRNG | Johannes Reibold | https://tinytapeout.com/chips/ttihp26a/tt_um_joh1x_prng |
| TTSKY25b | 815 | xorshift | fkdajlfas | https://tinytapeout.com/chips/ttsky25b/tt_um_fkd_xorshift |
| TTSKY25b | 877 | LFSR Driven Cryptography | Sai Surya | https://tinytapeout.com/chips/ttsky25b/tt_um_Sai222777 |
| TTSKY26a | 454 | Ring Oscillator PVT Sensor & TRNG | Prof. Santhosh Sivasubramani, IIT Delhi | https://tinytapeout.com/chips/ttsky26a/tt_um_santhosh_ring_osc |
| TTSKY26a | 460 | LFSR-Based Stochastic Neuron | Prof. Santhosh Sivasubramani, IIT Delhi | https://tinytapeout.com/chips/ttsky26a/tt_um_santhosh_stoch_neuron |
| TTSKY26a | 515 | Sky26a Advanced TRNG | Josh Gillespie | https://tinytapeout.com/chips/ttsky26a/tt_um_chicagojones_sky26a_trng |
| TTSKY26a | 522 | Current-Starved Ring Oscillator Based True Random Number Generator | Rakha Naufal | https://tinytapeout.com/chips/ttsky26a/tt_um_rakhanaufm_truerandom |
| TTSKY26a | 809 | Configurable Galois LFSR | Adithyan B, S Govind, Gouri Ajith | https://tinytapeout.com/chips/ttsky26a/809 |
| TTSKY26b | 196 | Logic-Locked 5-Bit RNGy | Ragib | https://tinytapeout.com/chips/ttsky26b/tt_um_gitragi_rng |
| TTSKY26b | 323 | 16 bit Galois LFSR based Random number generator-IEEE | Subir Maity, Jitendra Kr. Das | https://tinytapeout.com/chips/ttsky26b/tt_um_galois_lfsr16 |
| TTSKY26b | 460 | C0haotic RNG | onrkrts | https://tinytapeout.com/chips/ttsky26b/tt_um_chaotic_rng |

