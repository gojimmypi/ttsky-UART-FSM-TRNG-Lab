/*
 * Copyright (c) 2026 gojimmypi
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_gojimmypi (
// Optional Analog
//    input  wire       VGND,
//    input  wire       VDPWR,    // 1.8v power supply
//    input  wire       VAPWR,    // 3.3v power supply

    input  wire s7:0] ui_in,    // Dedicated inputs
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

 // Optional Analog
 // assign unused_ok = &{VGND, VDPWR, ena, clk, rst_n, uio_in, ua};

    assign unused_ok = &{ena, clk, rst_n, uio_in};

    assign uo_out = rst_n ? (ui_in + uio_in) : 8'h00;
    assign uio_out = 8'h00;
    assign uio_oe  = 8'h00;

endmodule

`default_nettype wire