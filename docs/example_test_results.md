# Example Test Results

<!--- # Do not move this file. Referenced by TT 4337 Documentation https://app.tinytapeout.com/projects/4337 --->


```text
Build PASSED
Flash...
Flashing file:
-rw-r--r-- 1 gojimmypi gojimmypi 294455 Jun  4 08:22 /mnt/c/workspace/ttgf-UART-FSM-TRNG-Lab/ulx3s/ulx3s.bit
ULX2S / ULX3S JTAG programmer v4.8 (git 96ebb45 built Oct  7 2020 22:42:00)
Copyright (C) Marko Zec, EMARD, gojimmypi, kost and contributors
Using USB cable: ULX3S FPGA 12K v3.0.3
Programming: 100%
Completed in 12.78 seconds.
/mnt/c/workspace/ttgf-UART-FSM-TRNG-Lab/test-hw
Press Enter to continue...

Skipping register reset. Use --reset-registers to start from configured defaults.

Running: version_if_present
Version probe response: b'Version 0.1.5d 6/3/2026\r'
PASS: Version command

Running: power_on_defaults
PASS: R0 default reg_ctrl
PASS: R1 default reg_src
PASS: R2 default reg_div
PASS: R3 default reg_mode
PASS: R4 default reg_oscen

Running: single_nibble_writes
PASS: E1 write enable
PASS: R0 after E1
PASS: E0 clear enable
PASS: R0 after E0
PASS: V1 set ctrl bit 1
PASS: R0 after V1
PASS: W1 set ctrl bit 2
PASS: R0 after W1
PASS: S3 set source
PASS: R1 after S3
PASS: S0 clear source
PASS: R1 after S0

Running: two_nibble_writes
PASS: D2A write divider
PASS: R2 after D2A
PASS: M5C write mode
PASS: R3 after M5C
PASS: O0F write oscillator enable
PASS: R4 after O0F

Running: read_only_registers_format
PASS: R5 status format
PASS: R6 rawlo format
PASS: R7 rawhi format

Running: crlf_handling
PASS: CRLF read accepted

Running: error_cases
PASS: Unknown command
PASS: Bad hex digit
PASS: Bad read register
PASS: Missing second digit
PASS: Unexpected extra byte

Running: repeated_reads
PASS: Repeated R2 read 1
PASS: Repeated R2 read 2
PASS: Repeated R2 read 3
PASS: Repeated R2 read 4
PASS: Repeated R2 read 5

Command test coverage:
PASS: all known commands have tests

Tests passed: 8
Tests skipped: 0
Tests failed: 0

PASS

Running: reset_config_registers
PASS: Reset E0
PASS: Reset V0
PASS: Reset W0
PASS: Reset S0
PASS: Reset D10
PASS: Reset M00
PASS: Reset O01

Running: version_if_present
Version probe response: b'Version 0.1.5d 6/3/2026\r'
PASS: Version command

Running: power_on_defaults
PASS: R0 default reg_ctrl
PASS: R1 default reg_src
PASS: R2 default reg_div
PASS: R3 default reg_mode
PASS: R4 default reg_oscen

Running: single_nibble_writes
PASS: E1 write enable
PASS: R0 after E1
PASS: E0 clear enable
PASS: R0 after E0
PASS: V1 set ctrl bit 1
PASS: R0 after V1
PASS: W1 set ctrl bit 2
PASS: R0 after W1
PASS: S3 set source
PASS: R1 after S3
PASS: S0 clear source
PASS: R1 after S0

Running: two_nibble_writes
PASS: D2A write divider
PASS: R2 after D2A
PASS: M5C write mode
PASS: R3 after M5C
PASS: O0F write oscillator enable
PASS: R4 after O0F

Running: read_only_registers_format
PASS: R5 status format
PASS: R6 rawlo format
PASS: R7 rawhi format

Running: crlf_handling
PASS: CRLF read accepted

Running: error_cases
PASS: Unknown command
PASS: Bad hex digit
PASS: Bad read register
PASS: Missing second digit
PASS: Unexpected extra byte

Running: repeated_reads
PASS: Repeated R2 read 1
PASS: Repeated R2 read 2
PASS: Repeated R2 read 3
PASS: Repeated R2 read 4
PASS: Repeated R2 read 5

Command test coverage:
PASS: all known commands have tests

Running: final_reset_config_registers
PASS: Reset E0
PASS: Reset V0
PASS: Reset W0
PASS: Reset S0
PASS: Reset D10
PASS: Reset M00
PASS: Reset O01

Tests passed: 10
Tests skipped: 0
Tests failed: 0

PASS

Running: TRNG S0 LFSR frozen samples
PASS: Configure E0
PASS: Configure source
PASS: Configure oscillator mask
PASS: Configure divider
PASS: Enable sampling
PASS: Freeze sampling
  sample 01: 0x1F34
PASS: Enable sampling
PASS: Freeze sampling
  sample 02: 0x4CE6
PASS: Enable sampling
PASS: Freeze sampling
  sample 03: 0xA63E
PASS: Enable sampling
PASS: Freeze sampling
  sample 04: 0x2381
PASS: Enable sampling
PASS: Freeze sampling
  sample 05: 0xAF56
PASS: Enable sampling
PASS: Freeze sampling
  sample 06: 0x81E9
PASS: Enable sampling
PASS: Freeze sampling
  sample 07: 0x1A72
PASS: Enable sampling
PASS: Freeze sampling
  sample 08: 0xA6FD

Evaluation: TRNG S0 LFSR frozen samples
  Samples:      8
  Unique:       8
  Zero samples: 0
  0xFFFF count: 0
  One bits:     65/128
  One ratio:    0.508
PASS: sample output changes
PASS: bit balance is reasonable for this small sample set

Running: TRNG S1 RO0/fallback path
PASS: Configure E0
PASS: Configure source
PASS: Configure oscillator mask
PASS: Configure divider
PASS: Enable sampling
PASS: Freeze sampling
  sample 01: 0x2B08
PASS: Enable sampling
PASS: Freeze sampling
  sample 02: 0x5E58
PASS: Enable sampling
PASS: Freeze sampling
  sample 03: 0x60B3
PASS: Enable sampling
PASS: Freeze sampling
  sample 04: 0x3295
PASS: Enable sampling
PASS: Freeze sampling
  sample 05: 0xE318
PASS: Enable sampling
PASS: Freeze sampling
  sample 06: 0x6387
PASS: Enable sampling
PASS: Freeze sampling
  sample 07: 0xCB05
PASS: Enable sampling
PASS: Freeze sampling
  sample 08: 0x3867

Evaluation: TRNG S1 RO0/fallback path
  Samples:      8
  Unique:       8
  Zero samples: 0
  0xFFFF count: 0
  One bits:     57/128
  One ratio:    0.445
PASS: sample output changes
PASS: bit balance is reasonable for this small sample set

Running: TRNG S2 ROX/fallback path
PASS: Configure E0
PASS: Configure source
PASS: Configure oscillator mask
PASS: Configure divider
PASS: Enable sampling
PASS: Freeze sampling
  sample 01: 0x4241
PASS: Enable sampling
PASS: Freeze sampling
  sample 02: 0x4634
PASS: Enable sampling
PASS: Freeze sampling
  sample 03: 0x26DA
PASS: Enable sampling
PASS: Freeze sampling
  sample 04: 0xD9AD
PASS: Enable sampling
PASS: Freeze sampling
  sample 05: 0xF7A3
PASS: Enable sampling
PASS: Freeze sampling
  sample 06: 0xC774
PASS: Enable sampling
PASS: Freeze sampling
  sample 07: 0xB924
PASS: Enable sampling
PASS: Freeze sampling
  sample 08: 0x73C0

Evaluation: TRNG S2 ROX/fallback path
  Samples:      8
  Unique:       8
  Zero samples: 0
  0xFFFF count: 0
  One bits:     62/128
  One ratio:    0.484
PASS: sample output changes
PASS: bit balance is reasonable for this small sample set

Running: TRNG S3 MIX/fallback path
PASS: Configure E0
PASS: Configure source
PASS: Configure oscillator mask
PASS: Configure divider
PASS: Enable sampling
PASS: Freeze sampling
  sample 01: 0xBD3F
PASS: Enable sampling
PASS: Freeze sampling
  sample 02: 0xC635
PASS: Enable sampling
PASS: Freeze sampling
  sample 03: 0xD417
PASS: Enable sampling
PASS: Freeze sampling
  sample 04: 0x43E2
PASS: Enable sampling
PASS: Freeze sampling
  sample 05: 0xC7E5
PASS: Enable sampling
PASS: Freeze sampling
  sample 06: 0x565C
PASS: Enable sampling
PASS: Freeze sampling
  sample 07: 0x1669
PASS: Enable sampling
PASS: Freeze sampling
  sample 08: 0xD573

Evaluation: TRNG S3 MIX/fallback path
  Samples:      8
  Unique:       8
  Zero samples: 0
  0xFFFF count: 0
  One bits:     70/128
  One ratio:    0.547
PASS: sample output changes
PASS: bit balance is reasonable for this small sample set

PASS

First LFSR sequence
  sample 01: 0x7F2E
  sample 02: 0x9F33
  sample 03: 0xFC1C
  sample 04: 0x6F03
  sample 05: 0x4B7D
  sample 06: 0x52C8
  sample 07: 0xD6B7
  sample 08: 0xEF2A

Second LFSR sequence
  sample 01: 0x7F2E
  sample 02: 0x9F33
  sample 03: 0xFC1C
  sample 04: 0x6F03
  sample 05: 0x4B7D
  sample 06: 0x52C8
  sample 07: 0xD6B7
  sample 08: 0xEF2A

Reproducibility evaluation:
PASS: LFSR sequence is reproducible

Sequence quality check:
  Samples:      8
  Unique:       8
  Zero samples: 0
  0xFFFF count: 0
  One bits:     75/128
  One ratio:    0.586
PASS: deterministic sequence is not stuck

PASS
```
