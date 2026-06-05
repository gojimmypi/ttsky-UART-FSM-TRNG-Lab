# iCE40 FPGA Tiny Tapeout

* WARNING: see generated `/src/_tt_fpga_top.v` file that may be undesired in other builds.



Set the `TT_PROJECT_ROOT` environment variable to the root of the project directory before running the tests or other scripts.

```bash
echo "Setting up environment variables for Tiny Tapeout FPGA project..."

# For example on WSL, the C:\workspace directory is mounted at /mnt/c/workspace
export WORKSPACE=/mnt/c/workspace
echo "WORKSPACE:            ${WORKSPACE}"

# Typically the name of the repo, for example: ttsky-UART-FSM-TRNG-Lab"
# See the src/project.v for the top module name
export TT_PROJECT_NAME="ttsky-UART-FSM-TRNG-Lab"
echo "TT_PROJECT_NAME:      ${TT_PROJECT_NAME}"

# For example: /mnt/c/workspace/ttsky-UART-FSM-TRNG-Lab
export TT_PROJECT_ROOT="${WORKSPACE}/${TT_PROJECT_NAME}"
echo "TT_PROJECT_ROOT:      ${TT_PROJECT_ROOT}"

# For example:  "tt_um_gojimmypi_ttsky_UART_FSM_TRNG_Lab"
export TT_TOP_NAME="tt_um_${USER}_${TT_PROJECT_NAME_ALT}"
echo "TT_TOP_NAME:          ${TT_TOP_NAME}"

# For example:  "/mnt/c/workspace/tt-support-tools-gojimmypi"
export TT_TOOLS=${WORKSPACE}/tt-support-tools-${USER}
echo "TT_TOOLS:             ${TT_TOOLS}"
```

## Ensure nextpnr is built for iCE40

```bash
cd $WORKSPACE

# icestorm is needed
git clone https://github.com/YosysHQ/icestorm.git
cd icestorm
make -j$(nproc)
sudo make install

# assuming nextpnr is already cloned at $WORKSPACE/nextpnr
cd $WORKSPACE/nextpnr/
mkdir -p build-ice40
cd build-ice40/
cmake ..  -DARCH=ice40  -DICESTORM_INSTALL_PREFIX=/usr/local  -DCMAKE_INSTALL_PREFIX=/usr/local
make -j$(nproc)
sudo make install
```

## Build project for iCE40 FPGA

```bash
cd "$TT_PROJECT_ROOT"

"$TT_TOOLS"/tt_fpga.py harden
```

Expected output similar to:

```text
$ $TT_TOOLS/tt_fpga.py harden
2026-06-04 14:08:12,968 - tt_fpga    - INFO     - Creating FPGA bitstream for [000 : unknown]

 /----------------------------------------------------------------------------\
 |  yosys -- Yosys Open SYnthesis Suite                                       |
 |  Copyright (C) 2012 - 2025  Claire Xenia Wolf <claire@yosyshq.com>         |
 |  Distributed under an ISC-like license, type "license" to see terms        |
 \----------------------------------------------------------------------------/
 Yosys 0.60+70 (git sha1 8101c87fa, g++ 11.4.0-1ubuntu1~22.04 -fPIC -O3)

-- Running command `read -define SYNTH' --

... [snip] ...

Info: Max frequency for clock 'clk$SB_IO_IN_$glb_clk': 43.37 MHz (PASS at 12.00 MHz)

Info: Max delay <async>                       -> <async>                      : 11.24 ns
Info: Max delay <async>                       -> posedge clk$SB_IO_IN_$glb_clk: 22.06 ns
Info: Max delay posedge clk$SB_IO_IN_$glb_clk -> <async>                      : 8.27 ns

Info: Slack histogram:

... [snip] ...

Info: Program finished normally.
2026-06-04 14:08:20,336 - tt_fpga    - INFO     - Bitstream created successfully: /mnt/c/workspace/ttsky-UART-FSM-TRNG-Lab/build/tt_um_gojimmypi_ttsky_UART_FSM_TRNG_Lab.bin
```

## Upload project to iCE40 FPGA

```bash
cd "$TT_PROJECT_ROOT"

# For example: /mnt/c/workspace/tt-support-tools-gojimmypi/tt_fpga.py configure --port /dev/ttyS6 --upload --name ttsky-UART-FSM-TRNG-Lab
"$TT_TOOLS/tt_fpga.py" configure --port /dev/ttyS6 --upload --name "$TT_TOP_NAME" --set-default
```

Expected output similar to:

```text
$ "$TT_TOOLS/tt_fpga.py" configure --port /dev/ttyS6 --upload --name "$TT_TOP_NAME"
Uploading build/tt_um_gojimmypi_ttsky_UART_FSM_TRNG_Lab.bin
cp build/tt_um_gojimmypi_ttsky_UART_FSM_TRNG_Lab.bin :/bitstreams/tt_um_gojimmypi_ttsky_UART_FSM_TRNG_Lab.bin
Up to date: /bitstreams/tt_um_gojimmypi_ttsky_UART_FSM_TRNG_Lab.bin
```

## Initial Test

When first powering on:

### Sanity Checks

```python
tt
```

### Factory Test

```python
tt.shuttle.tt_um_factory_test.enable()
```


## Interact with the FPGA

When first powering on, first load image:


```python
tt.shuttle.tt_um_gojimmypi_ttsky_UART_FSM_TRNG_Lab.enable()

# Set clock to 25MHz
tt.clock_project_PWM(25000000)

tt.reset_project(True)
tt.reset_project(False)

```

Reset:

```python
tt.ui_in = 0x00
tt.reset_project(True)
tt.reset_project(False)
tt.uo_out
tt.uio_out
```

### Test

Paste this into reply prompt:

```python
import time

def b8(x):
    s = bin(x)[2:]
    return "0" * (8 - len(s)) + s

tt.shuttle.tt_um_gojimmypi_ttsky_UART_FSM_TRNG_Lab.enable()
tt.clock_project_PWM(25000000)

# ui_in[4] = 1 selects SPI/debug-serial mode
# ui_in[3] = 1 idles UART RX high
tt.ui_in = 0x18

tt.reset_project(True)
time.sleep_ms(5)
tt.reset_project(False)
time.sleep_ms(20)

uo = int(tt.uo_out)
uio = int(tt.uio_out)

print("tt      =", tt)
print("ui_in   = 0x18  00011000")
print("uo_out  = 0x%02x  %s" % (uo, b8(uo)))
print("uio_out = 0x%02x  %s" % (uio, b8(uio)))

print("UART TX idle uo_out[4] =", (uo >> 4) & 1)
print("status[2:0]            = 0x%x" % ((uo >> 1) & 7))
print("trng_bit               =", uo & 1)
print("reg_rawlo[2:0]         = 0x%x" % ((uo >> 5) & 7))
print("reg_rawhi[7:4]         = 0x%x" % ((uio >> 4) & 15))
print("SPI MISO / JTAG TDO    =", (uio >> 2) & 1)

if ((uo >> 4) & 1) == 1:
    print("PASS: UART TX is idle high.")
else:
    print("FAIL: UART TX is not idle high.")

if ((uo >> 1) & 7) == 4:
    print("PASS: reset/status baseline is 0x4.")
else:
    print("WARN: status baseline changed.")

```

Expected output:

```text
 >>>
>>> import time
>>>
>>> def b8(x):
...     s = bin(x)[2:]
...     return "0" * (8 - len(s)) + s
...
>>> tt.shuttle.tt_um_gojimmypi_ttsky_UART_FSM_TRNG_Lab.enable()
ttboard.fpga.fpga_mux: Enable design tt_um_gojimmypi_ttsky_UART_FSM_TRNG_Lab
Configuring PIO with frequency: 16000000 Hz
State machine activated
SS low, starting transmission
Transmission complete, total bytes: 104090
State machine deactivated, SS high
ttboard.demoboard: Resetting system clock to default 125000000.0Hz
ttboard.demoboard: Setting RP2040 system clock to 133000000Hz
ttboard.demoboard: Clocking at 100Hz
>>> tt.clock_project_PWM(25000000)
ttboard.demoboard: Setting RP2040 system clock to 100000000Hz
ttboard.demoboard: Clocking at 25000000Hz
<PWM slice=0 channel=0 invert=0>
>>>
>>> # ui_in[4] = 1 selects SPI/debug-serial mode
>>> # ui_in[3] = 1 idles UART RX high
>>> tt.ui_in = 0x18
>>>
>>> tt.reset_project(True)
ttboard.demoboard: Changing reset to output mode
>>> time.sleep_ms(5)
>>> tt.reset_project(False)
>>> time.sleep_ms(20)
>>>
>>> uo = int(tt.uo_out)
>>> uio = int(tt.uio_out)
>>>
>>> print("tt      =", tt)
tt      = <DemoBoard in ASIC_MANUAL_INPUTS, auto-clocking @ 25000000 FPGA project 'FPGA:tt_um_gojimmypi_ttsky_UART_FSM_TRNG_Lab'>
>>> print("ui_in   = 0x18  00011000")
ui_in   = 0x18  00011000
>>> print("uo_out  = 0x%02x  %s" % (uo, b8(uo)))
uo_out  = 0x18  00011000
>>> print("uio_out = 0x%02x  %s" % (uio, b8(uio)))
uio_out = 0x00  00000000
>>>
>>> print("UART TX idle uo_out[4] =", (uo >> 4) & 1)
UART TX idle uo_out[4] = 1
>>> print("status[2:0]            = 0x%x" % ((uo >> 1) & 7))
status[2:0]            = 0x4
>>> print("trng_bit               =", uo & 1)
trng_bit               = 0
>>> print("reg_rawlo[2:0]         = 0x%x" % ((uo >> 5) & 7))
reg_rawlo[2:0]         = 0x0
>>> print("reg_rawhi[7:4]         = 0x%x" % ((uio >> 4) & 15))
reg_rawhi[7:4]         = 0x0
>>> print("SPI MISO / JTAG TDO    =", (uio >> 2) & 1)
SPI MISO / JTAG TDO    = 0
>>>
>>> if ((uo >> 4) & 1) == 1:
...     print("PASS: UART TX is idle high.")
... else:
...     print("FAIL: UART TX is not idle high.")
...
PASS: UART TX is idle high.
>>> if ((uo >> 1) & 7) == 4:
...     print("PASS: reset/status baseline is 0x4.")
... else:
...     print("WARN: status baseline changed.")
...
PASS: reset/status baseline is 0x4.
>>>

```

## References

- https://store.tinytapeout.com/products/FPGA-Development-Kit-p813805747
- https://tinytapeout.com/guides/get-started-demoboard-etr/
- https://github.com/TinyTapeout/tt-micropython-firmware/
- https://github.com/TinyTapeout/breakout-pcb/tree/nextgenv3/ASIC-simulator/ttdbv3-fpga-ICE40UP5k
- https://github.com/TinyTapeout/tt-demo-pcb/
