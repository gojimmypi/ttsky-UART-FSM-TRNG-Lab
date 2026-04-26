.PHONY: all test bit prog clean

.DELETE_ON_ERROR:

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

# Optionally force a loopback
FORCE_LOOPBACK ?= 0
YOSYS_DEFS :=

ifeq ($(FORCE_LOOPBACK),1)
    YOSYS_DEFS += -DFORCE_LOOPBACK
endif

ROOT     := ..
SRC_DIR  := $(ROOT)/src
TEST_DIR := $(ROOT)/test

# TT uses tt_um_gojimmypi_ttsky_UART_FSM_TRNG_Lab, but we need a ulx3s wrapper for that in ./top_ulx3s.v
# RTL_TOP  := tt_um_gojimmypi_ttsky_UART_FSM_TRNG_Lab
RTL_TOP  := top_ulx3s
TB_TOP   := tb

RTL_SRCS := $(SRC_DIR)/*.v  $(SRC_DIR)/UART/*.v  $(SRC_DIR)/UART/TRNG/*.v  ./top_ulx3s.v
TB_SRCS  := $(TEST_DIR)/tb.v

# -----------------------------
# Verilator (simulation)
# -----------------------------
VERILATOR := verilator
VFLAGS    := -Wall --trace --timing -Wno-fatal -DULX3S

VDIR      := obj_dir
SIMEXE    := V$(TB_TOP)

# -----------------------------
# ULX3S build (synthesis)
# -----------------------------
YOSYS      := yosys
NEXTPNR    := nextpnr-ecp5
ECPPACK    := ecppack

LPF        := ulx3s_v20.lpf

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
	$(VERILATOR) $(VFLAGS) --binary \
	    --top-module $(TB_TOP) \
	    $(RTL_SRCS) $(TB_SRCS)

# -----------------------------
# ULX3S synthesis flow
# -----------------------------
bit: $(BITFILE)

$(JSON): $(RTL_SRCS)
	$(YOSYS) $(YOSYS_DEFS) -p "read_verilog -DULX3S $(RTL_SRCS); synth_ecp5 -top $(RTL_TOP) -json $(JSON)"

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
