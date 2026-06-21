# ATTRIBUTION

This project builds upon open-source tools, templates, and publicly available reference designs.  
The author gratefully acknowledges the following sources.

## Matt Venn

ASIC Rock Star!

https://www.zerotoasiccourse.com/matt_venn/

---

## TinyTapeout Templates

This project is derived from TinyTapeout reference templates:

- https://github.com/TinyTapeout/ttsky-analog-template
- https://github.com/TinyTapeout/ttsky-verilog-template
- https://github.com/TinyTapeout/ttgf-verilog-template

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

## NIST Online Resources

See https://csrc.nist.gov/projects/random-bit-generation and more.

---

## Community Acknowledgment

Thanks to the TinyTapeout community, FPGA developers, and open-source contributors
whose shared knowledge and examples made this project possible.

---

## Help with timing / setup / slew / fanout violations

> Nonzero max slew violation / fanout / cap - really problems?

Extra thanks `Essen`, `Luke - HRAOUBG`, `toivoh`, `RebelMike`, `tnt`, `namibj` for the [help in Discord thread](https://discord.com/channels/1009193568256135208/1513299711975489566/1513299711975489566).

A lot was learned about the toolchain, GDS log files in the GH action, configuration fine tuning, and more.

---

## All the TT RNG Projects that came before

ChaptGPT was asked to find all the TT related TRNG projects. This is the generated list:

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

Of the above projects, ChatGPT was asked which are similar to this project. This is the response:

| Similarity           | Project                                                                               | Why it is similar                                                                                                                                                                                                                                         | Main difference                                                                                                                                                                  |
| -------------------- | ------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Very close**       | **TTSKY26a 515 — Sky26a Advanced TRNG**; (2x2 Full AI Claude / Gemini)                | It is explicitly a “research-grade” TRNG based on phase jitter from an **8-oscillator RO bank**, with characterization and debug features. That overlaps strongly with your RO-bank/TRNG/debug direction. ([tinytapeout.com][1])                          | It sounds more narrowly focused on an advanced TRNG, while yours is broader: UART/SPI lab interface, register map, raw/conditioned modes, and hardware entropy explorer framing. |
| **Very close**       | **TTSKY26a 454 — Ring Oscillator PVT Sensor & TRNG** (1x1 good oscillator reference)  | It uses **gatable ring oscillators**, frequency counters, CDC synchronization, prescaler, XOR-jitter TRNG, health monitor, and PVT/fault/aging characterization. That is highly adjacent to your RO entropy + observability goals. ([tinytapeout.com][2]) | It is more PVT/frequency-characterization oriented; your project is more UART/SPI-accessible TRNG/PUF/FSM lab oriented.                                                          |
| **Close**            | **TTIHP26a 242 — True(er) Random Number Generator (TRNG)**                            | It is a fully digital TRNG harvesting entropy from **phase noise/jitter of free-running ring oscillators**, then sampling and whitening into 8-bit words. ([tinytapeout.com][3])                                                                          | It appears simpler: direct TRNG output path, not the broader multi-interface exploration/test platform you are building.                                                         |
| **Close**            | **TTIHP25a 746 — TRNG**                                                               | It has raw entropy and hashed output modes, UART output, health tests, and randomness/statistical-test framing. ([tinytapeout.com][4])                                                                                                                    | It uses SHA-256 conditioning and UART output; your project’s current direction is more lightweight hardware conditioning/register access, with SPI and UART control.             |
| **Moderately close** | **TTSKY26a 522 — Current-Starved Ring Oscillator Based True Random Number Generator** | The title alone makes it clearly RO/TRNG-related, and specifically analog-ish/current-starved RO based. The chip page lists it as a true random number generator. ([tinytapeout.com][5])                                                                  | Likely more custom/analog oscillator focused; your current design is standard-cell RO/TRNG plus digital lab/control infrastructure.                                              |
| **Moderately close** | **TTIHP26a — RO-based security primitives / `tt_um_ro_puf_trng`**                     | The slug strongly suggests the same conceptual family: **ring oscillator + PUF + TRNG**. That is very close to your “TRNG PUF Explorer” idea.                                                                                                             | I could not reliably open the project page contents from TinyTapeout, so I would treat this as a strong lead but not a confirmed detailed match.                                 |
| **Somewhat close**   | **TTIHP26a 561 — VGA multiplex with TRNG**                                            | It uses a TRNG from **sampling a ring oscillator** to randomly select among VGA projects. ([tinytapeout.com][6])                                                                                                                                          | The TRNG is a subcomponent for a VGA demo, not the project’s core research/control/debug target.                                                                                 |
| **Somewhat close**   | **TTSKY26b 460 — C0haotic RNG**                                                       | It is an RNG, but based on a programmable nonlinear chaotic map with 32-bit state variables and arithmetic feedback. ([tinytapeout.com][7])                                                                                                               | Algorithmic/chaotic deterministic-ish generator style, not RO jitter entropy. Much less similar architecturally.                                                                 |

[1]: https://www.tinytapeout.com/chips/ttsky26a/tt_um_chicagojones_sky26a_trng "515 Sky26a Advanced TRNG :: Quicker, easier and cheaper to make your own chip!"
[2]: https://www.tinytapeout.com/chips/ttsky26a/454 "454 Ring Oscillator PVT Sensor & TRNG :: Quicker, easier and cheaper to make your own chip!"
[3]: https://tinytapeout.com/chips/ttihp26a/242 "242 True(er) Random Number Generator (TRNG) :: Quicker, easier and cheaper to make your own chip!"
[4]: https://tinytapeout.com/chips/ttihp25a/tt_um_bilal_trng "746 TRNG :: Quicker, easier and cheaper to make your own chip!"
[5]: https://tinytapeout.com/chips/ttsky26a/ "Tiny Tapeout SKY 26a :: Quicker, easier and cheaper to make your own chip!"
[6]: https://tinytapeout.com/chips/ttihp26a/561 "561 VGA multiplex with TRNG :: Quicker, easier and cheaper to make your own chip!"
[7]: https://tinytapeout.com/chips/ttsky26b/tt_um_chaotic_rng "460 C0haotic RNG :: Quicker, easier and cheaper to make your own chip!"
