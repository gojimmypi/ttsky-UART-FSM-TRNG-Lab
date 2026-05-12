/*
 * Copyright (c) 2026 gojimmypi
 * SPDX-License-Identifier: Apache-2.0
 *
 * See ATTRIBUTION.md for third-party sources and credits.
 *
 * file: project.v
 *
 * Top-level wrapper for the Tiny Tapeout project.
 *
 * If the ULX3S FPGA is used, see the /ulx3s/top_ulx3s.v wrapper file and define ULX3S when building. 
 */
`default_nettype none

`include "target_pdk.v"

`ifdef ULX3S
    `timescale 1ns/1ps
`else
    /* Tiny Tapeout doesn't support timescale directives, so we can ignore it. */
`endif /* ULX3S */


/* There's about a 5% (~ 100 cells) increase in the number of cells when using long strings.
 * Currently only the version string is implemented. */
`define USE_LONG_STRINGS
`define UART_ENABLED
`define SPI_ENABLED
`define TRNG_ENABLED

/* optionally define an SPI test byte. Default is 0x42 */
`define SPI_TEST_BYTE 8'hD2

/* Pick zero or one of these SPI tests: */
`define SPI_TEST_FIXED
// `define SPI_TEST_ECHO

/* Conditional TRNG settings */
`ifdef ULX3S
    /* Do not define TRNG_USE_RO when building for ULX3S since
     * the real RO-based TRNG is only available in the Tiny Tapeout environment. */
    `ifdef TRNG_USE_RO
        PROJECT_ULX3S_MUST_NOT_USE_TRNG_USE_RO u_stop ();
    `endif
    `ifdef TRNG_ALLOW_REAL_RO
        PROJECT_ULX3S_MUST_NOT_USE_TRNG_ALLOW_REAL_RO u_stop ();
    `endif
`else
    `ifdef __pnr__
        /* HACK ALERT: __pnr__ does not conclusively prove that we are building for Tiny Tapeout, 
         * but it is a strong indicator that we are in an environment where the real RO-based TRNG can be used. */
        `define TRNG_USE_RO
        `define TRNG_ALLOW_REAL_RO
    `else
        /* some other non ULX3S, non ASIC path. Detect if REAL RO defined externally and abort */
        `ifdef TRNG_USE_RO
            PROJECT_NON_ASIC_MUST_NOT_USE_TRNG_USE_RO u_stop ();
        `endif
        `ifdef TRNG_ALLOW_REAL_RO
            PROJECT_NON_ASIC_MUST_NOT_USE_TRNG_ALLOW_REAL_RO u_stop ();
        `endif
    `endif
`endif

/*
 * Build Environment Configuration
 *
 * The codebase is designed to be portable across different FPGA platforms and simulation environments.
 * Conditional compilation directives are used to include or exclude code based on the target environment.
 * This allows for a single codebase that can be built for both the ULX3S FPGA and the Tiny Tapeout platform,
 * while still supporting environment-specific features and optimizations.
 *
 * Key points:
 * - The `ULX3S` macro is defined when building for the ULX3S FPGA, enabling ULX3S-specific code paths.
 * - When `ULX3S` is not defined, it is assumed that the build target is Tiny Tapeout, and Tiny Tapeout-specific code paths are enabled.
 * - This structure allows for clean separation of environment-specific code while maintaining a shared core logic.
 */
`ifdef ULX3S
    /* The ./ulx3s/Makefile includes references to needed files */
`else
    /* Tiny Tapeout needs to include all the files directly since it doesn't support Makefiles.
     * or list them in /info.yaml file (pick one, don't mix) */
    `include "tt_um_main.v"
    `include "SPI/spi_slave.v"
    `include "UART/uart_rx_min.v"
    `include "UART/uart_tx_min.v"
    `include "UART/uart_trng_ascii_core.v"
    `include "TRNG/trng_cfg_ascii_core.v"
    `ifdef TRNG_ENABLED
        `include "TRNG/trng_lab_core.v"
    `else
        `include "TRNG/trng_stub.v"
    `endif /* TRNG_ENABLED */
`endif /* ULX3S */

/* See companion project: SKY130 (ChipFoundry) tt_um_gojimmypi_ttsky_UART_FSM_TRNG_Lab */

/* Assume TT needs this file to be called project.v 
 * but the module is called tt_um_gojimmypi_ttgf_UART_FSM_TRNG_Lab - so disable warning: */

 /* Define a unique name for the module based on the target PDK. 
  * This allows the same project.v file to be used across different PDK targets without modification, 
  * while still adhering to any naming requirements imposed by the Tiny Tapeout platform. 
  * 
  * There's no Makefile to extract name from info.yaml, so the module name is hardcoded here: */
`ifdef PDK_TARGET_SKY130
/* verilator lint_off DECLFILENAME */
module tt_um_gojimmypi_ttsky_UART_FSM_TRNG_Lab
/* verilator lint_on DECLFILENAME */

`elsif PDK_TARGET_GF180
/* verilator lint_off DECLFILENAME */
module tt_um_gojimmypi_ttgf_UART_FSM_TRNG_Lab
/* verilator lint_on DECLFILENAME */

`else
/* Only SKY130 and GF180 supported at this time. See target_pdk.v 
 * There will likely be an error later with this name and the need for real RO */
module UART_FSM_TRNG_Lab
`endif

#(
    parameter [31:0] CLOCK_HZ  = 32'd25000000,  /* default clock is 25 MHz     */
    parameter [31:0] UART_BAUD = 32'd115200     /* default UART is 115200 baud */
)
(
    // Optional Analog
    //    input  wire       VGND,
    //    input  wire       VDPWR,    // 1.8v power supply
    //    input  wire       VAPWR,    // 3.3v power supply

    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)

    //    inout  wire [7:0] ua,       // Analog pins, only ua[5:0] can be used

    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    wire unused_ok;

    tt_um_main
    #(
        .CLOCK_HZ(CLOCK_HZ),
        .UART_BAUD(UART_BAUD)
    )
    u_core
    (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .ena(ena),
        .clk(clk),
        .rst_n(rst_n)
    );

    // Optional Analog
    // assign unused_ok = &{VGND, VDPWR, ena, clk, rst_n, uio_in, ua};

    assign unused_ok = &{ena, clk, rst_n, uio_in};

    `ifdef ULX3S
        always @(posedge clk) begin
            if (rst_n) begin
                $display("t=%0t ui_in=%h uio_in=%h uo_out=%h",
                         $time, ui_in, uio_in, uo_out);
            end
        end
    `else
        /* FORCE_LOOPBACK not supported outside of ULX3S since it relies on specific pin mappings 
         *  and test features that may not be present in other environments. */
        `ifdef FORCE_LOOPBACK
            MODULE_FORCE_LOOPBACK_MUST_NOT_BE_ENABLED u_stop ();
        `endif
    `endif /* ULX3S */

endmodule

/* Settings Sanity Check */
`ifdef SPI_TEST_FIXED
    `ifdef SPI_TEST_ECHO
        MODULE_SPI_TEST_ECHO_MUST_NOT_BE_ENABLED_WITH_SPI_TEST_FIXED u_stop ();
    `endif
`endif

`default_nettype wire
