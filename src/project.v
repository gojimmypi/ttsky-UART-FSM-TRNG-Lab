/*
 * Copyright (c) 2026 gojimmypi
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none
`timescale 1ns/1ps

/* Assume TT needs this file to be called project.v but the module is called tt_um_gojimmypi - so disable warning: */
/* verilator lint_off DECLFILENAME */
module tt_um_gojimmypi (
/* verilator lint_on DECLFILENAME */

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

    input  wire       ena,      // always 1 when the design is powered
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    wire unused_ok;

    tt_um_uart_trng_ascii u_core
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
