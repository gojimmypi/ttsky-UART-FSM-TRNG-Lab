/*
 * Copyright (c) 2026 gojimmypi
 * SPDX-License-Identifier: Apache-2.0
 *
 * See ATTRIBUTION.md for third-party sources and credits.
 *
 * file: tt_um_main.v
 *
 * Tiny Tapeout wrapper for the TRNG ASCII core.
 *
 * Purpose:
 * - Exposes the project through the standard Tiny Tapeout pin interface.
 * - Adapts one TT input pin to UART RX and one TT output pin to UART TX.
 * - Surfaces a few internal status bits on GPIOs for simple board-level debug.
 *
 * Pin usage in this wrapper:
 * - ui_in[7:4]   : reserved for future use, currently ignored
 * - ui_in[3]     : UART RX input to the core
 * - ui_in[2:0]   : reserved for future use, currently ignored
 *
 * - uo_out[7:5]  : selected low raw-data bits
 * - uo_out[4]    : UART TX output from the core
 * - uo_out[3:1]  : selected status bits
 * - uo_out[0]    : trng_bit
 *
 * - uio_out[7:4] : reg_rawhi[7:4] when SPI is enabled
 * - uio_out[2]   : SPI MISO when SPI is enabled
 * - uio_out[1:0] : SPI inputs (CS, MOSI) via uio_in[] when SPI is enabled
 * - uio_out[7:0] : reg_rawhi byte (driven when SPI is disabled)
 *
 * - uio_oe[7:0]  : UIO direction control
 *
 * This module contains almost no behavior of its own. It is mostly a pin-map
 * and visibility wrapper around uart_trng_ascii_core.
 */
`default_nettype none

module tt_um_main 
#(
    parameter [31:0] CLOCK_HZ  = 32'd25000000,
    parameter [31:0] UART_BAUD = 32'd115200
)
(
    /* For Tiny Tapeout, these are the only ports you can use. 
     * See:    https://tinytapeout.com/specs/pinouts/         */
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    /* Internal debug/configuration buses exported by the core. */
    wire [7:0] reg_ctrl;
    wire [7:0] reg_src;
    wire [7:0] reg_div;
    wire [7:0] reg_mode;
    wire [7:0] reg_oscen;
    wire [7:0] reg_status;
    wire [7:0] reg_rawlo;
    wire [7:0] reg_rawhi;
    wire       trng_bit;
    wire       uart_tx;

    reg        uart_rx_meta;
    reg        uart_rx_sync;

`ifdef SPI_ENABLED
    wire spi_sck;
    wire spi_mosi;
    wire spi_cs_n;
    wire spi_miso;
`endif

    /* TODO check unused wires when SPI and/or UART not enabled */
    wire _unused_ui_in = &{ui_in[7:4], uio_in[2], ui_in[2:0]};

    wire _unused_debug_regs = &{
        reg_ctrl,
        reg_src,
        reg_div,
        reg_mode,
        reg_oscen,
        reg_status[7:3],
        reg_rawlo[7:3], 
        reg_rawhi[3:0]
    };

    /*
     * Keep unused TT inputs referenced so synthesis does not warn.
     * ena is mandatory in the TT interface but not functionally used here.
     * uio_in is reserved for future use.
     */
    wire unused_ok;
`ifdef SPI_ENABLED
    assign unused_ok = &{ena, uio_in[7:4], spi_mosi};
`else
    assign unused_ok = &{ena, uio_in};
`endif

    /* 
     * Synchronize asynchronous UART RX input to the local clock domain.
     *
     * The external UART RX pin (ui_in[3]) is asynchronous to clk and can
     * violate setup/hold timing if sampled directly by synchronous logic.
     *
     * A two-stage synchronizer reduces metastability risk and prevents
     * X propagation/glitches observed during GF180 gate-level simulation.
     */
     always @(posedge clk) begin
        if (!rst_n) begin
            uart_rx_meta <= 1'b1;
            uart_rx_sync <= 1'b1;
        end else begin
            uart_rx_meta <= ui_in[3];
            uart_rx_sync <= uart_rx_meta;
        end
    end

    uart_trng_ascii_core
    #(
        .CLOCK_HZ(CLOCK_HZ),
        .UART_BAUD(UART_BAUD)
    )
    u_core
    (
        .clk(clk),
        .rst_n(rst_n),
        .uart_rx_i(uart_rx_sync),
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
     * Export one UART pin plus a few convenient status/data bits.
     * This is handy during bring-up because it gives visual/logic-analyzer
     * access to internal state without changing the core.
     */
    assign uo_out[4] = uart_tx;
    assign uo_out[0] = trng_bit;
    assign uo_out[1] = reg_status[0];
    assign uo_out[2] = reg_status[1];
    assign uo_out[3] = reg_status[2];
    assign uo_out[5] = reg_rawlo[0];
    assign uo_out[6] = reg_rawlo[1];
    assign uo_out[7] = reg_rawlo[2];

`ifdef SPI_ENABLED
    assign spi_cs_n = uio_in[0];
    assign spi_mosi = uio_in[1];
    assign spi_sck  = uio_in[3];

    tt_spi_slave u_spi_slave
    (
        .clk(clk),
        .rst_n(rst_n),
        .spi_sck(spi_sck),
        .spi_cs_n(spi_cs_n),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso)
    );

    assign uio_out[0]   = 1'b0;
    assign uio_out[1]   = 1'b0;
    assign uio_out[2]   = spi_miso;
    assign uio_out[3]   = 1'b0;

    assign uio_out[7:4] = reg_rawhi[7:4];

    assign uio_oe = 8'hF4;
`else
    assign uio_out = reg_rawhi;
    assign uio_oe  = 8'hFF;
`endif

endmodule

`default_nettype wire
