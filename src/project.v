/*
 * Copyright (c) 2026 gojimmypi
 * SPDX-License-Identifier: Apache-2.0
 *
 * See ATTRIBUTION.md for third-party sources and credits.
 *
 * file: project.v
 *
 * Top-level wrapper for the Tiny Tapeout project.
 */
`default_nettype none


/* There's about a 5% (~ 100 cells) increase in the number of cells when using long strings.
 * Currently only the version string is implemented. */
`define USE_LONG_STRINGS

`ifdef ULX3S
    /* Makefile includes references to needed files */
`else
    /* Tiny Tapeout needs to include all the files directly since it doesn't support Makefiles. */
    `include "tt_um_uart_trng_ascii.v"
    `include "UART/uart_rx_min.v"
    `include "UART/uart_tx_min.v"
    `include "UART/uart_trng_ascii_core.v"
    `include "UART/TRNG/trng_cfg_ascii_core.v"
    `include "UART/TRNG/trng_stub.v"
`endif /* ULX3S */

`ifdef ULX3S
    `timescale 1ns/1ps
`else
    /* Tiny Tapeout doesn't support timescale directives, so we can ignore it. */
`endif /* ULX3S */

/* See companion prject: SKY130 (ChipFoundry) tt_um_gojimmypi_ttsky_UART_FSM_TRNG_Lab

/* Assume TT needs this file to be called project.v 
 * but the module is called tt_um_gojimmypi_ttgf_UART_FSM_TRNG_Lab - so disable warning: */

/* verilator lint_off DECLFILENAME */
module tt_um_gojimmypi_ttsky_UART_FSM_TRNG_Lab
/* verilator lint_on DECLFILENAME */
#(
    parameter [31:0] CLOCK_HZ  = 32'd25000000,
    parameter [31:0] UART_BAUD = 32'd115200
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

    tt_um_uart_trng_ascii 
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

`default_nettype wire
