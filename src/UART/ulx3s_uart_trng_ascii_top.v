/*
 * Copyright (c) 2026 gojimmypi
 * SPDX-License-Identifier: Apache-2.0
 *
 * ULX3S board wrapper for the UART/TRNG ASCII core.
 *
 * Purpose:
 * - Lets the same core used for Tiny Tapeout also be exercised directly on the
 *   ULX3S FPGA board.
 * - Connects board-level UART pins and a simple LED bus.
 *
 * Why this is useful:
 * - It gives a fast hardware-debug path before worrying about Tiny Tapeout pin
 *   packing, wrapper behavior, or demoboard details.
 */
module ulx3s_uart_trng_ascii_top
#(
    parameter integer CLKS_PER_BIT = 217
)
(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       uart_rx,
    output wire       uart_tx,
    output wire [7:0] led
);

    /* Internal debug/configuration signals exported by the core. */
    wire [7:0] reg_ctrl;
    wire [7:0] reg_src;
    wire [7:0] reg_div;
    wire [7:0] reg_mode;
    wire [7:0] reg_oscen;
    wire [7:0] reg_status;
    wire [7:0] reg_rawlo;
    wire [7:0] reg_rawhi;
    wire       trng_bit;

    uart_trng_ascii_core
    #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    )
    u_core
    (
        .clk(clk),
        .rst_n(rst_n),
        .uart_rx_i(uart_rx),
        .uart_tx_o(uart_tx),
        .reg_ctrl_o(reg_ctrl),
        .reg_src_o(reg_src),
        .reg_div_o(reg_div),
        .reg_mode_o(reg_mode),
        .reg_oscen_o(reg_oscen),
        .reg_status_o(reg_status),
        .reg_rawlo_o(reg_rawlo),
        .reg_rawhi_o(reg_rawhi),
        .trng_bit_o(trng_bit)
    );

    /*
     * For simple visual feedback, show the low data byte on LEDs.
     * This is convenient when confirming that the stub is changing state.
     */
    assign led = reg_rawlo;

endmodule
