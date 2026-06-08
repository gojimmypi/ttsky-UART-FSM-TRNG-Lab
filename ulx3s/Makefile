.PHONY: all test bit prog clean

.DELETE_ON_ERROR:

# init
YOSYS_DEFS :=

# This Makefile is for the ULX3S
YOSYS_DEFS += -DULX3S

# ULX3S board LPF Constraint File selection.
# Default is v316 (v317 and v318 use same lpf). Override with:
#   make bit ULX3S_BOARD_VERSION=v20
ULX3S_BOARD_VERSION ?= v316

# See https://github.com/ulx3s/ulx3s/tree/master/doc/constraints
ifeq ($(ULX3S_BOARD_VERSION),v20)
	# This is also the default for v307
    LPF := ulx3s_v20.lpf
else ifeq ($(ULX3S_BOARD_VERSION),v17)
	# Note the reference file name
    LPF := ulx3s_v17patch.lpf
else ifeq ($(ULX3S_BOARD_VERSION),v17patch)
    LPF := ulx3s_v17patch.lpf
else ifeq ($(ULX3S_BOARD_VERSION),v307)
	# v307 and v20 use the same constraint file
    LPF := ulx3s_v20.lpf
else ifeq ($(ULX3S_BOARD_VERSION),v314)
    LPF := ulx3s_v314.lpf
else ifeq ($(ULX3S_BOARD_VERSION),v316)
    LPF := ulx3s_v316.lpf
else ifeq ($(ULX3S_BOARD_VERSION),v317)
	# v317 and v316 use the same constraint file
    LPF := ulx3s_v316.lpf
else ifeq ($(ULX3S_BOARD_VERSION),v318)
	# v318 and v316 use the same constraint file
    LPF := ulx3s_v316.lpf
else
	# some specific versions of boards use a common LPF file, grouped here in parenthesis:
	$(error Unsupported ULX3S_BOARD_VERSION "$(ULX3S_BOARD_VERSION)". Use (v17, v17patch), (v20, v307), (v314), or (v316, v317, v318))
endif

# --package options for nextpnr-ecp5. See below
PACKAGE := CABGA381

# -------------------------------------
# 3 flavors of ULX3S, pick ONE DEVICE
# or specify: 
#   make bit DEVICE=25k   # overrides
# -------------------------------------
# 12F
# DEVICE ?= 25k

# 45F
# DEVICE ?= 45k

# 85F
DEVICE ?= 85k

FREQ := 25

# Optionally force a UART loopback
FORCE_LOOPBACK ?= 0
ifeq ($(FORCE_LOOPBACK),1)
    YOSYS_DEFS += -DFORCE_LOOPBACK
endif

# Optionally force a deep UART loopback
FORCE_DEEP_LOOPBACK ?= 0
ifeq ($(FORCE_DEEP_LOOPBACK),1)
    YOSYS_DEFS += -DFORCE_DEEP_LOOPBACK
endif

# The ESP32 on the ULX3S sits behind the FPGA and needs pass-through logic to control it.
# ESP32_BOOT_CONTROL_ENABLED enables ESP32 EN/GPIO0 control from the FPGA.
#
# ESP32_BOOT_RTS_DTR_ENABLED enables hands-off esptool reset/boot control from US1 FTDI.
# Without ESP32_BOOT_RTS_DTR_ENABLED, BTN0 controls wifi_en and BTN1 controls wifi_gpio0.
#   - Hold PWR/Reset then press BTN1 to enter ESP32 bootloader mode for flashing.
#
# See top_ulx3s.v for details.
ESP32_BOOT_CONTROL_ENABLED ?= 1
ifeq ($(ESP32_BOOT_CONTROL_ENABLED),1)
    YOSYS_DEFS += -DESP32_BOOT_CONTROL_ENABLED
endif

# Does the ULX3S have a soft SPI implemented for the ESP32?
# Enabled by default to the TT project.
# Enables the ULX3S ESP32 SPI path into the TT uio[3:0] SPI pins.
ULX3S_SPI_ENABLED ?= 1
ifeq ($(ULX3S_SPI_ENABLED),1)
    YOSYS_DEFS += -DULX3S_SPI_ENABLED
endif

# Experimental FTDI RTS/DTR auto-boot control for ESP32 programming.
ESP32_BOOT_RTS_DTR_ENABLED ?= 1
ifeq ($(ESP32_BOOT_RTS_DTR_ENABLED),1)
    YOSYS_DEFS += -DESP32_BOOT_RTS_DTR_ENABLED
endif

ROOT     := ..
SRC_DIR  := $(ROOT)/src
TEST_DIR := $(ROOT)/test

# Abort if Tiny Tapeout tooling generated its FPGA top in the project src tree.
# That wrapper is not part of the ULX3S build and can conflict with top_ulx3s.v.
GENERATED_TT_FPGA_TOP := $(SRC_DIR)/_tt_fpga_top.v
ifneq ($(wildcard $(GENERATED_TT_FPGA_TOP)),)
$(error Found $(GENERATED_TT_FPGA_TOP). Remove it before building ULX3S targets)
endif

# Get the TOP_MODULE from the info.yaml file, and pass it as a define. 
INFO_YAML ?= ../info.yaml
TOP_MODULE := $(shell sed -n 's/^[[:space:]]*top_module:[[:space:]]*"\?\([^"]*\)"\?/\1/p' $(INFO_YAML))

# unused?
# COMPILE_ARGS += -DTT_TOP_MODULE=$(TOP_MODULE)

ifeq ($(TOP_MODULE),)
$(error Could not find top_module in $(INFO_YAML))
endif

YOSYS_DEFS += -DTT_TOP_MODULE=$(TOP_MODULE)

# TT uses tt_um_gojimmypi_ttsky_UART_FSM_TRNG_Lab, but we need a ulx3s wrapper for that in ./top_ulx3s.v
# RTL_TOP  := tt_um_gojimmypi_ttsky_UART_FSM_TRNG_Lab
RTL_TOP  := top_ulx3s
TB_TOP   := tb

RTL_SRCS := $(SRC_DIR)/*.v  $(SRC_DIR)/UART/*.v  $(SRC_DIR)/TRNG/*.v  $(SRC_DIR)/SPI/*.v  $(SRC_DIR)/PINS/*.v  $(SRC_DIR)/JTAG/*.v  ./top_ulx3s.v
TB_SRCS  := $(TEST_DIR)/tb.v

# ESP32 support could be optional for the ULX3S and is not needed for the TT, so we put it in a separate file.
RTL_SRCS += ./esp32_prog_ctrl.v
YOSYS_DEFS += -DHAS_ESP32_PROG_CTRL

# -----------------------------
# Verilator (simulation)
# -----------------------------
VERILATOR := verilator
VFLAGS    := -Wall --trace --timing -Wno-fatal

VDIR      := obj_dir
SIMEXE    := V$(TB_TOP)

# -----------------------------
# ULX3S build (synthesis)
# -----------------------------
YOSYS      := yosys
NEXTPNR    := nextpnr-ecp5
ECPPACK    := ecppack


$(info =====================================)
$(info ULX3S board version: $(ULX3S_BOARD_VERSION))
$(info Using LPF file:      $(LPF))
$(info FPGA device:         $(DEVICE))
$(info FPGA package:        $(PACKAGE))
$(info =====================================)

# Pass macros such as ULX3S_BOARD_VERSION_v317 to yosys for conditional verilog
YOSYS_DEFS += -DULX3S_BOARD_VERSION_$(ULX3S_BOARD_VERSION)

JSON       := project.json
CONFIG     := ulx3s_out.config
BITFILE    := ulx3s.bit

# -----------------------------
# Default target
# -----------------------------
all: $(BITFILE)

# -----------------------------
# Simulation
# -----------------------------
test: $(VDIR)/$(SIMEXE)
	./$(VDIR)/$(SIMEXE)

$(VDIR)/$(SIMEXE): $(RTL_SRCS) $(TB_SRCS)
	$(VERILATOR) $(VFLAGS) $(YOSYS_DEFS) --binary \
		--top-module $(TB_TOP) \
		$(RTL_SRCS) $(TB_SRCS)

# -----------------------------
# ULX3S synthesis flow
# -----------------------------
bit: $(BITFILE)

YOSYS_INCLUDE_DIRS := -I$(SRC_DIR)

$(JSON): $(RTL_SRCS)
	$(YOSYS) $(YOSYS_DEFS) -p "read_verilog $(YOSYS_INCLUDE_DIRS) $(RTL_SRCS); synth_ecp5 -top $(RTL_TOP) -json $(JSON)"

$(CONFIG): $(JSON)
	$(NEXTPNR) \
	    --$(DEVICE) \
	    --json $(JSON) \
	    --lpf-allow-unconstrained \
	    --freq $(FREQ) \
	    --package $(PACKAGE) \
	    --lpf $(LPF) \
	    --textcfg $(CONFIG)

$(BITFILE): $(CONFIG)
	$(ECPPACK) $(CONFIG) $(BITFILE)

# -----------------------------
# Program FPGA
# -----------------------------
prog: $(BITFILE)
	../../bin/ujprog $(BITFILE)

clean:
	rm -rf $(VDIR)
	rm -f *.vcd *.fst
	rm -f $(JSON) $(CONFIG) $(BITFILE)
