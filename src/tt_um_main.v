/*
 * Copyright (c) 2026 gojimmypi
 * SPDX-License-Identifier: Apache-2.0
 *
 * See ATTRIBUTION.md for third-party sources and credits.
 *
 * file: tt_um_main.v
 *
 * Tiny Tapeout wrapper for the TRNG ASCII core.
 * Included by project.v and requires project_config.v
 *
 * Purpose:
 * - Exposes the project through the standard Tiny Tapeout pin interface.
 * - Adapts one TT input pin to UART RX and one TT output pin to UART TX.
 * - Surfaces a few internal status bits on GPIOs for simple board-level debug.
 *
 * Pin usage in this wrapper:
 * - ui_in[7:5]   : reserved for future use, currently ignored
 * - ui_in[4]     : SPI/JTAG select, 1 = SPI, 0 = JTAG
 * - ui_in[3]     : UART RX input to the core
 * - ui_in[2:0]   : reserved for future use, currently ignored
 *
 * - uo_out[7:5]  : selected low raw-data bits
 * - uo_out[4]    : UART TX output from the core
 * - uo_out[3:1]  : selected status bits
 * - uo_out[0]    : trng_bit
 *
 * - uio[0]       : SPI CS_N / JTAG TMS when serial debug is enabled
 * - uio[1]       : SPI MOSI / JTAG TDI when serial debug is enabled
 * - uio[2]       : SPI MISO / JTAG TDO when serial debug is enabled
 * - uio[3]       : SPI SCK  / JTAG TCK when serial debug is enabled
 * - uio_out[7:4] : reg_rawhi[7:4] when serial debug is enabled
 * - uio_out[7:0] : reg_rawhi byte when serial debug is disabled
 *
 * - uio_oe[7:0]  : UIO direction control
 *
 * This module contains almost no behavior of its own. It is mostly a pin-map
 * and visibility wrapper around uart_trng_ascii_core.
 */
`default_nettype none

`ifdef SIM_JTAG_CORE_TB
    `timescale 1ns / 1ps
`endif

`include "project_config.v"

module tt_um_main 
#(
    parameter [31:0] CLOCK_HZ  = `PROJECT_CLOCK_HZ,
    parameter [31:0] UART_BAUD = `PROJECT_UART_BAUD
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
     /* Boilerplate parameter checking */
    generate
        if (CLOCK_HZ == 32'd0) begin : gen_bad_clock_hz
            PROJECT_MUST_NOT_USE_ZERO_CLOCK u_stop ();
        end

        if (UART_BAUD == 32'd0) begin : gen_bad_uart_baud
            PROJECT_MUST_NOT_USE_ZERO_UART_BAUD u_stop ();
        end

        if ((CLOCK_HZ / UART_BAUD) == 32'd0) begin : gen_bad_uart_divider
            PROJECT_UART_DIVIDER_MUST_NOT_BE_ZERO u_stop ();
        end
    endgenerate


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

`ifdef SPI_REG_ACCESS
    wire       spi_reg_wr_en;
    wire [2:0] spi_reg_addr;
    wire [7:0] spi_reg_wdata;
    wire [7:0] spi_reg_rdata;

    `ifdef SPI_ENABLED
        wire       spi_slave_reg_wr_en;
        wire [2:0] spi_slave_reg_addr;
        wire [7:0] spi_slave_reg_wdata;
    `endif
    `ifdef JTAG_ENABLED
        wire       jtag_reg_wr_en;
        wire [7:0] jtag_reg_addr;
        wire [7:0] jtag_reg_wdata;
        wire _unused_jtag_reg_addr = &{1'b0, jtag_reg_addr[7:3]};
    `endif
`endif /* SPI_REG_ACCESS */

`ifdef SPI_ENABLED
    wire spi_sck;
    wire spi_mosi;
    wire spi_cs_n;
    wire spi_miso;
    `ifndef SPI_REG_ACCESS
        wire       spi_unused_reg_wr_en;
        wire [2:0] spi_unused_reg_addr;
        wire [7:0] spi_unused_reg_wdata;
    `endif
`endif /* SPI_ENABLED */

`ifdef JTAG_ENABLED
    wire jtag_tck;
    wire jtag_tms;
    wire jtag_tdi;
    wire jtag_tdo;
    wire debug_is_jtag;
`endif

    /* TODO check unused wires when SPI and/or UART not enabled */
`ifdef SPI_ENABLED
    `ifdef JTAG_ENABLED
        wire _unused_ui_in = &{ui_in[7:5], ui_in[2:0]};
    `else
        wire _unused_ui_in = &{ui_in[7:4], ui_in[2:0]};
    `endif
`else
    /* not SPI_ENABLED */
    wire _unused_inputs = &{ui_in[7:4], uio_in[2], ui_in[2:0]};
`endif /* !SPI_ENABLED */

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
    assign unused_ok = &{ena, uio_in[7:4], uio_in[2], spi_mosi};
`else
    `ifdef JTAG_ENABLED
        assign unused_ok = &{ena, uio_in[7:4], jtag_tdi};
    `else
        assign unused_ok = &{ena, uio_in};
    `endif
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
`ifdef SPI_REG_ACCESS
        ,
        .spi_reg_wr_en(spi_reg_wr_en),
        .spi_reg_addr(spi_reg_addr),
        .spi_reg_wdata(spi_reg_wdata),
        .spi_reg_rdata(spi_reg_rdata)
`endif
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

`ifdef JTAG_ENABLED
    /* ui_in[4] = 1: ESP32 SPI owns uio[3:0] (default, unconnected = 1: PULLMODE=UP IO_TYPE=LVCMOS33 DRIVE=4;)
     * ui_in[4] = 0: external JTAG header owns uio[3:0] */
    assign debug_is_jtag = ~ui_in[4]; /* invert logic since pull-up default on ULX3S wrapper means unconnected = SPI (not JTAG)  */

    /* TODO: what happens with unconnected TT pim? */

    assign jtag_tms = uio_in[0];
    assign jtag_tdi = uio_in[1];
    assign jtag_tck = uio_in[3];

    jtag_core u_jtag_core
    (
        .clk(clk),
        .rst_n(rst_n),
        .ena(ena & debug_is_jtag),
        .tck_i(jtag_tck),
        .tms_i(jtag_tms),
        .tdi_i(jtag_tdi),
        .tdo_o(jtag_tdo),

    `ifdef SPI_REG_ACCESS
        .reg_addr_o(jtag_reg_addr),
        .reg_wr_o(jtag_reg_wr_en),
        .reg_wdata_o(jtag_reg_wdata),
        .reg_rdata_i(spi_reg_rdata)
    `else
        .reg_addr_o(),
        .reg_wr_o(),
        .reg_wdata_o(),
        .reg_rdata_i(8'h00)
    `endif
    );
`else
    /* No JTAG */
    /* assign debug_is_jtag = 1'b0; */
`endif


`ifdef SPI_REG_ACCESS
    `ifdef JTAG_ENABLED
        assign spi_reg_wr_en = debug_is_jtag ? jtag_reg_wr_en : spi_slave_reg_wr_en;
        assign spi_reg_addr  = debug_is_jtag ? jtag_reg_addr[2:0] : spi_slave_reg_addr;
        assign spi_reg_wdata = debug_is_jtag ? jtag_reg_wdata : spi_slave_reg_wdata;
    `else
        assign spi_reg_wr_en = spi_slave_reg_wr_en;
        assign spi_reg_addr  = spi_slave_reg_addr;
        assign spi_reg_wdata = spi_slave_reg_wdata;
    `endif
`endif

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
        .spi_miso(spi_miso),

    `ifdef SPI_REG_ACCESS
        .reg_wr_en(spi_slave_reg_wr_en),
        .reg_addr(spi_slave_reg_addr),
        .reg_wdata(spi_slave_reg_wdata),
        .reg_rdata(spi_reg_rdata)
    `else
        .reg_wr_en(spi_unused_reg_wr_en),
        .reg_addr(spi_unused_reg_addr),
        .reg_wdata(spi_unused_reg_wdata),
        .reg_rdata(8'h00)
    `endif
    );

    assign uio_out[0]   = 1'b0;
    assign uio_out[1]   = 1'b0;

    `ifdef JTAG_ENABLED
        assign uio_out[2]   = debug_is_jtag ? jtag_tdo : spi_miso;
    `else
        assign uio_out[2]   = spi_miso;
    `endif

    assign uio_out[3]   = 1'b0;

    assign uio_out[7:4] = reg_rawhi[7:4];

    assign uio_oe = 8'hF4;

    `ifndef SPI_REG_ACCESS
        wire _unused_spi_reg_outputs = &{
            1'b0,
            spi_unused_reg_wr_en,
            spi_unused_reg_addr,
            spi_unused_reg_wdata
        };
    `endif
    /* end SPI_ENABLED */
`else
    /* not SPI_ENABLED */
    `ifdef JTAG_ENABLED
        assign uio_out[0]   = 1'b0;
        assign uio_out[1]   = 1'b0;
        assign uio_out[2]   = jtag_tdo;
        assign uio_out[3]   = 1'b0;
        assign uio_out[7:4] = reg_rawhi[7:4];

        assign uio_oe = 8'hF4;
    `else
        assign uio_out = reg_rawhi;
        assign uio_oe  = 8'hFF;
    `endif
`endif /* not SPI_ENABLED */

endmodule

`default_nettype wire
