# UART FSM TRNG Lab Datasheet

Document revision: 0.1  
RTL revision string: `Version 0.1.4c 5/23/2026`  
Project family: Tiny Tapeout UART/SPI configurable TRNG experiment  
Primary top modules: `tt_um_gojimmypi_ttsky_UART_FSM_TRNG_Lab`, `tt_um_gojimmypi_ttgf_UART_FSM_TRNG_Lab`  
License: Apache-2.0, as declared in the source files

## 1. Overview

The UART FSM TRNG Lab is a Tiny Tapeout compatible experimental random-number and entropy-source project. It exposes a small register bank through an ASCII UART command interface and, when enabled, an SPI mode 0 register-access interface. The design is intended for laboratory bring-up, education, FPGA validation, and ASIC ring-oscillator entropy experiments.

The core supports multiple sample sources:

- Deterministic LFSR source for repeatable tests
- Single ring-oscillator sample source
- XOR of multiple ring-oscillator sources
- Mixed source combining ring-oscillator and LFSR-derived state

The design is not a certified cryptographic random number generator. Raw output should be characterized, health-tested, and conditioned before use in security-sensitive systems.

## 2. Key Features

- Tiny Tapeout standard digital pin interface
- UART RX/TX control path using ASCII commands
- Optional SPI register-access slave
- SPI mode 0, MSB first
- Shared UART and SPI register bank
- 8-byte logical register map
- Configurable sample divider
- Selectable entropy/sample source
- Ring oscillator enable mask
- Deterministic single-step mode for test reproducibility
- Reset control through a configuration bit
- Default 25 MHz project clock
- Default 115200 baud UART
- ASIC real ring-oscillator path for selected PDK builds
- FPGA/simulation-safe LFSR tap substitute when real ring oscillators are disabled

## 3. Design Status and Intended Use

This block is intended as an experimental TRNG lab core. It is suitable for:

- Tiny Tapeout project demonstration
- FPGA bring-up on ULX3S or similar wrappers
- UART command parser testing
- SPI register interface testing
- Ring oscillator experimentation in supported ASIC flows
- Deterministic regression testing using the LFSR source

It is not, by itself, suitable as a drop-in cryptographic RNG. The raw output is unconditioned and no formal entropy claim is made in this datasheet.

## 4. Source Files

The main RTL files are:

| File | Purpose |
| --- | --- |
| `project.v` | Top-level Tiny Tapeout project wrapper and project feature defines |
| `project_config.v` | Project clock and UART baud configuration |
| `target_pdk.v` | PDK target selection |
| `tt_um_main.v` | Tiny Tapeout pin mapping and UART/SPI/TRNG integration |
| `UART/uart_rx_min.v` | Minimal UART receiver |
| `UART/uart_tx_min.v` | Minimal UART transmitter |
| `UART/uart_trng_ascii_core.v` | UART and TRNG integration core |
| `TRNG/trng_cfg_ascii_core.v` | ASCII command parser and register bank |
| `TRNG/trng_lab_core.v` | Experimental TRNG/lab source logic |
| `TRNG/trng_stub.v` | Stub/test TRNG replacement when the lab core is not enabled |
| `SPI/spi_slave.v` | SPI mode 0 register-access slave |
| `JTAG/jtag_core.v` | Optional JTAG-related logic |

## 5. Top-Level Parameters

| Parameter | Default | Description |
| --- | ---: | --- |
| `CLOCK_HZ` | `25000000` | Project clock frequency in Hz |
| `UART_BAUD` | `115200` | UART baud rate |

The source contains parameter checks that intentionally fail elaboration if either parameter is zero or if `CLOCK_HZ / UART_BAUD` would be zero.

The `ULX3S_USE_GN12_50MHZ` configuration path can set `PROJECT_CLOCK_HZ` to 50 MHz for the optional ULX3S `gn12` clock path. Normal builds use the 25 MHz project clock.

## 6. Build-Time Feature Defines

| Define | Purpose |
| --- | --- |
| `UART_ENABLED` | Enables UART-related integration |
| `SPI_ENABLED` | Enables the SPI slave pin path |
| `SPI_REG_ACCESS` | Enables SPI access to the shared register bank |
| `TRNG_ENABLED` | Selects the TRNG lab core instead of the stub core |
| `JTAG_ENABLED` | Enables JTAG-related build integration |
| `USE_LONG_STRINGS` | Enables the long version string reply path |
| `TRNG_USE_RO` | Requests the real ring-oscillator TRNG path |
| `TRNG_ALLOW_REAL_RO` | Explicit guard required with `TRNG_USE_RO` |
| `PDK_TARGET_SKY130` | Selects SKY130 inverter cell instantiation |
| `PDK_TARGET_GF180` | Selects GF180 inverter cell instantiation |
| `ULX3S` | Selects ULX3S FPGA wrapper/build behavior |

For ULX3S builds, the source intentionally rejects `TRNG_USE_RO` and `TRNG_ALLOW_REAL_RO`. FPGA and normal simulation paths use deterministic LFSR-derived substitutes for the ring oscillator signals.

## 7. Functional Block Diagram

```text
              Tiny Tapeout pins
                    |
                    v
              tt_um_main.v
                    |
        +-----------+------------+
        |                        |
        v                        v
  UART RX/TX path          Optional SPI path
  uart_rx_min.v            spi_slave.v
  uart_tx_min.v                  |
        |                        |
        +-----------+------------+
                    |
                    v
          trng_cfg_ascii_core.v
          ASCII parser + registers
                    |
                    v
            trng_lab_core.v
       LFSR / RO / mixed sampling
                    |
                    v
       status, raw low byte, raw high byte
```

## 8. Clock and Reset

| Signal | Active level | Description |
| --- | --- | --- |
| `clk` | Rising edge | Main synchronous project clock |
| `rst_n` | Low | Global reset |

On reset, the register bank is initialized as shown below:

| Register | Reset value |
| --- | ---: |
| `reg_ctrl` | `0x00` |
| `reg_src` | `0x00` |
| `reg_div` | `0x10` |
| `reg_mode` | `0x00` |
| `reg_oscen` | `0x01` |

The TRNG lab core internally resets the LFSR to `0x1ACE`, clears `sample_shift`, clears the sample counter, clears status, and clears raw output registers.

## 9. Tiny Tapeout Pin Map

### Dedicated inputs: `ui_in[7:0]`

| Pin | Direction | Function |
| --- | --- | --- |
| `ui_in[7:5]` | Input | Reserved / unused |
| `ui_in[4]`   | Input | SPI/JTAG select, 1 = SPI, 0 = JTAG |
| `ui_in[3]`   | Input | UART RX |
| `ui_in[2:0]` | Input | Reserved / unused |

The UART RX input is synchronized through a two-stage synchronizer before it enters the UART receive logic.

### Dedicated outputs: `uo_out[7:0]`

| Pin | Direction | Function |
| --- | --- | --- |
| `uo_out[0]` | Output | `trng_bit` |
| `uo_out[1]` | Output | `reg_status[0]` |
| `uo_out[2]` | Output | `reg_status[1]` |
| `uo_out[3]` | Output | `reg_status[2]` |
| `uo_out[4]` | Output | UART TX |
| `uo_out[5]` | Output | `reg_rawlo[0]` |
| `uo_out[6]` | Output | `reg_rawlo[1]` |
| `uo_out[7]` | Output | `reg_rawlo[2]` |

### Bidirectional IO: `uio[7:0]` when SPI is enabled

| Pin | Direction | Function |
| --- | --- | --- |
| `uio[0]` | Input | SPI CS_N |
| `uio[1]` | Input | SPI MOSI |
| `uio[2]` | Output | SPI MISO |
| `uio[3]` | Input | SPI SCK |
| `uio[7:4]` | Output | `reg_rawhi[7:4]` debug visibility |

When SPI is enabled, `uio_oe` is driven as `0xF4`, making `uio[2]` and `uio[7:4]` outputs while leaving `uio[0]`, `uio[1]`, and `uio[3]` as inputs.

### Bidirectional IO when SPI is disabled

When SPI is not enabled, `uio_out[7:0]` drives the full `reg_rawhi` byte and `uio_oe` is driven as `0xFF`.

## 10. UART Interface

### UART settings

| Setting | Value |
| --- | --- |
| Baud rate | `UART_BAUD`, default 115200 |
| Data bits | 8 |
| Parity | None |
| Stop bits | 1 |
| Byte order | ASCII command bytes |
| Command terminator | Carriage return, `0x0D` |

Line feed, `0x0A`, is ignored in command wait states, allowing common CRLF terminal behavior.

### UART command summary

| Command | Arguments | Effect | Reply |
| --- | --- | --- | --- |
| `E0` / `E1` | 1 hex nibble | Write `reg_ctrl[0]`, TRNG enable | `OK<CR>` |
| `Sx` | 1 hex nibble | Write `reg_src[1:0]` | `OK<CR>` |
| `Vx` | 1 hex nibble | Write `reg_ctrl[1]`, deterministic single-step request | `OK<CR>` |
| `Wx` | 1 hex nibble | Write `reg_ctrl[2]`, TRNG reset control | `OK<CR>` |
| `Dxx` | 2 hex nibbles | Write `reg_div[7:0]` | `OK<CR>` |
| `Mxx` | 2 hex nibbles | Write `reg_mode[7:0]` | `OK<CR>` |
| `Oxx` | 2 hex nibbles | Write `reg_oscen[7:0]` | `OK<CR>` |
| `Rn` | `n = 0..7` | Read register `n` | `Rn=HH<CR>` |
| `V` | None | Version query | Version string + `<CR>` |

Invalid syntax returns `?<CR>`.

### UART command examples

```text
V<CR>       -> Version 0.1.4c 5/23/2026<CR>
R2<CR>      -> R2=10<CR>
E1<CR>      -> OK<CR>
D10<CR>     -> OK<CR>
S0<CR>      -> OK<CR>
O01<CR>     -> OK<CR>
R6<CR>      -> R6=HH<CR>
R7<CR>      -> R7=HH<CR>
```

To reconstruct the current 16-bit raw sample from UART register reads:

```text
raw16 = (R7 << 8) | R6
```

## 11. SPI Interface

The SPI interface is available when `SPI_ENABLED` and `SPI_REG_ACCESS` are enabled.

### SPI electrical/protocol settings

| Setting | Value |
| --- | --- |
| Mode | SPI mode 0 |
| CPOL | 0 |
| CPHA | 0 |
| Bit order | MSB first |
| Chip select | Active low, `CS_N` |
| Register address width | 3 bits |

### SPI command byte

| Bit field | Description |
| --- | --- |
| `bit[7]` | `1` = read, `0` = write |
| `bit[6:3]` | Ignored |
| `bit[2:0]` | Register address `0..7` |

### SPI read transaction

```text
byte 0: 0x80 | addr
byte 1: dummy byte; returned MISO byte is the register value
```

For example, reading `reg_rawlo` at address 6:

```text
TX: 86 00
RX: xx HH
```

The useful read value is the second received byte.

### SPI write transaction

```text
byte 0: addr
byte 1: data byte
```

Only addresses 0 through 4 are writable. Writes to addresses 5 through 7 are ignored by the register bank.

For example, writing divider register `R2 = 0x10`:

```text
TX: 02 10
```

## 12. Register Map

| Addr | UART read | Name | Access | Reset | Description |
| ---: | --- | --- | --- | ---: | --- |
| 0 | `R0` | `reg_ctrl` | R/W | `0x00` | Control bits |
| 1 | `R1` | `reg_src` | R/W | `0x00` | Source selection |
| 2 | `R2` | `reg_div` | R/W | `0x10` | Sample divider |
| 3 | `R3` | `reg_mode` | R/W | `0x00` | Mode/debug field |
| 4 | `R4` | `reg_oscen` | R/W | `0x01` | Ring oscillator enable mask |
| 5 | `R5` | `reg_status` | Read-only | `0x00` | Status mirror |
| 6 | `R6` | `reg_rawlo` | Read-only | `0x00` | Raw sample low byte |
| 7 | `R7` | `reg_rawhi` | Read-only | `0x00` | Raw sample high byte |

## 13. Control Register: `reg_ctrl`, Address 0

| Bit | Name | Description |
| ---: | --- | --- |
| 0 | `enable` | Enables periodic sampling when set |
| 1 | `step` | Deterministic single-step request. A rising edge creates one sample event |
| 2 | `reset` | Resets the TRNG lab core while asserted |
| 7:3 | Reserved | Currently unused |

UART aliases:

| Command | Field |
| --- | --- |
| `E0` / `E1` | `reg_ctrl[0]` |
| `V0` / `V1` | `reg_ctrl[1]` |
| `W0` / `W1` | `reg_ctrl[2]` |

Note: bare `V<CR>` is the version query. `V0<CR>` and `V1<CR>` are control writes.

## 14. Source Register: `reg_src`, Address 1

Only `reg_src[1:0]` is used.

| Value | Source | Description |
| ---: | --- | --- |
| `0` | `SRC_LFSR` | LFSR bit source, deterministic and repeatable |
| `1` | `SRC_RO0` | Sampled ring oscillator 0 source |
| `2` | `SRC_ROX` | XOR of the ring oscillator raw bits |
| `3` | `SRC_MIX` | Mixed source using RO XOR, LFSR taps, and sample history |

UART alias: `Sx<CR>` writes `reg_src[1:0]`.

## 15. Divider Register: `reg_div`, Address 2

`reg_div` controls the periodic sample interval when `reg_ctrl[0]` is enabled. The internal sample counter increments while enabled. A sample event is generated when:

```text
sample_ctr >= reg_div
```

A single-step event through `reg_ctrl[1]` can also generate a sample event without waiting for the periodic divider.

UART alias: `Dxx<CR>` writes the full divider byte.

## 16. Mode Register: `reg_mode`, Address 3

`reg_mode` is a full 8-bit writable register. In the current TRNG lab core, `reg_mode[2:0]` is mirrored into `reg_status[7:5]`. Other bits are reserved for future use.

UART alias: `Mxx<CR>` writes the full mode byte.

## 17. Oscillator Enable Register: `reg_oscen`, Address 4

`reg_oscen` is an 8-bit enable mask for the ring oscillator instances in real RO builds.

| Bit | Real RO instance | Stage count |
| ---: | --- | ---: |
| 0 | `u_ro0` | 3 |
| 1 | `u_ro1` | 5 |
| 2 | `u_ro2` | 7 |
| 3 | `u_ro3` | 9 |
| 4 | `u_ro4` | 11 |
| 5 | `u_ro5` | 13 |
| 6 | `u_ro6` | 15 |
| 7 | `u_ro7` | 17 |

In FPGA and normal simulation builds, the RO raw bits are derived from LFSR taps instead of real ring oscillators.

UART alias: `Oxx<CR>` writes the full oscillator enable mask.

## 18. Status Register: `reg_status`, Address 5

| Bit field | Description |
| --- | --- |
| `bit[0]` | Mirrors TRNG enable |
| `bit[1]` | Mirrors sample tick condition |
| `bit[2]` | Indicates at least one oscillator enable bit is set |
| `bits[4:3]` | Mirrors source selection |
| `bits[7:5]` | Mirrors `reg_mode[2:0]` |

`reg_status` is read-only from the external UART/SPI register interfaces.

## 19. Raw Output Registers: `reg_rawlo` and `reg_rawhi`

The TRNG lab core maintains a 16-bit sample shift register. On each sample event, the selected source bit is shifted into the sample history and the raw output registers are updated.

| Register | Description |
| --- | --- |
| `reg_rawlo` | Low byte of the latest raw sample history |
| `reg_rawhi` | High byte of the latest raw sample history |

The current 16-bit raw sample value is reconstructed as:

```text
raw16 = (reg_rawhi << 8) | reg_rawlo
```

## 20. Sampling Behavior

A sample event occurs when either condition is true:

```text
do_sample = (enable && sample_tick) || step_pulse
```

Where:

```text
sample_tick = sample_ctr >= reg_div
step_pulse  = reg_ctrl[1] && !previous_reg_ctrl_bit_1
```

On each sample event:

- `sample_ctr` is cleared to zero
- The 16-bit LFSR advances
- The selected source bit shifts into `sample_shift`
- `reg_rawlo` and `reg_rawhi` are updated

When enable is deasserted, the sample counter is held at zero. A single-step pulse can still advance one sample.

## 21. LFSR Details

The deterministic LFSR path is used for repeatable tests and for FPGA/simulation-safe substitute RO signals. On TRNG reset, the LFSR seed is:

```text
0x1ACE
```

The next LFSR bit is computed as:

```text
lfsr_next_bit = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]
```

The LFSR then shifts as:

```text
lfsr <= {lfsr[14:0], lfsr_next_bit}
```

This path is deterministic and should not be treated as an entropy source.

## 22. Ring Oscillator Path

In real ASIC RO builds, the design instantiates eight odd-length ring oscillators with stage counts from 3 to 17. The oscillator outputs feed the source selection logic through synchronizers.

In FPGA and normal simulation builds, real ring oscillators are not instantiated. Instead, the RO raw signals are mapped to LFSR taps so the rest of the design can be tested safely without combinational oscillator loops.

Supported real RO PDK cell paths in the current source are:

| PDK define | Inverter cell |
| --- | --- |
| `PDK_TARGET_SKY130` | `sky130_fd_sc_hd__inv_2` |
| `PDK_TARGET_GF180` | `gf180mcu_fd_sc_mcu7t5v0__inv_1` |

## 23. Recommended Bring-Up Sequence

A conservative UART bring-up sequence is:

```text
V<CR>       Read version string
R0<CR>      Confirm control reset value
R1<CR>      Confirm source reset value
R2<CR>      Confirm divider reset value, expected 10
R3<CR>      Confirm mode reset value
R4<CR>      Confirm oscillator enable reset value, expected 01
S0<CR>      Select deterministic LFSR source
D10<CR>     Set divider to 0x10
M00<CR>     Clear mode
O01<CR>     Enable oscillator mask bit 0
E1<CR>      Enable sampling
R6<CR>      Read raw low byte
R7<CR>      Read raw high byte
```

For deterministic regression testing, use source `S0`, assert and release reset through `W1` and `W0`, then issue single-step pulses through `V1` and `V0` as required by the test harness.

## 24. Known Deterministic Regression Sequence

With the deterministic LFSR path and the established single-step/reset test flow, the known-good 16-bit sample sequence used in current hardware regression is:

```text
sample 01: 0x7F2E
sample 02: 0x9F33
sample 03: 0xFC1C
sample 04: 0x6F03
sample 05: 0x4B7D
sample 06: 0x52C8
sample 07: 0xD6B7
sample 08: 0xEF2A
```

This sequence is a reproducibility check for the deterministic path. It is not an entropy-quality claim.

## 25. UART and SPI Concurrency Notes

UART and SPI share the same logical register bank. SPI writes are applied when `spi_reg_wr_en` is asserted. UART commands also update the same configuration registers.

When using SPI as a passive monitor while UART is active, individual register reads are separate transactions. Reading `reg_rawlo` and `reg_rawhi` separately is not atomic, so the two bytes may occasionally come from adjacent sample updates. For exact sample capture, add an atomic snapshot/latch mechanism or temporarily stop sampling before reading both bytes.

## 26. Limitations

- No cryptographic certification is claimed.
- No built-in conditioner, extractor, or DRBG is provided by this RTL block.
- Raw RO entropy quality must be measured on the actual ASIC implementation.
- FPGA and normal simulation builds do not use real ring oscillators.
- SPI multi-byte reads of raw low/high registers are not atomic.
- UART command parsing is intentionally small and accepts only the documented command forms.
- Register addresses 5 through 7 are read-only through SPI writes and UART write aliases do not target them.

## 27. Characterization Recommendations

Before using ASIC RO output as a source of entropy, characterize at minimum:

- Raw bit bias for each source selection
- Bit transition rate
- Autocorrelation
- Per-oscillator behavior across voltage and temperature
- Behavior across process corners and multiple chips
- Startup behavior after reset
- Sensitivity to `reg_div` and `reg_oscen`
- Health test behavior under stuck oscillator conditions

For security use, add a conditioning function and a health-test strategy appropriate for the target application.

## 28. Revision History

| Datasheet rev | Date | Notes |
| --- | --- | --- |
| 0.1 | 2026-05-23 | Initial datasheet generated from current TRNG source package |

trng_datasheet.md.txt
Displaying trng_datasheet.md.txt.