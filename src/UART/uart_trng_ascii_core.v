/*
 * Copyright (c) 2026 gojimmypi
 * SPDX-License-Identifier: Apache-2.0
 *
 * See ATTRIBUTION.md for third-party sources and credits.
 *
 * file: uart_trng_ascii_core.v
 *
 * Core integration block for the UART/TRNG ASCII design.
 *
 * Purpose:
 * - Connects the minimal UART RX and TX blocks.
 * - In normal mode, connects the ASCII command parser to the TRNG stub.
 * - In FORCE_DEEP_LOOPBACK mode, bypasses the parser/TRNG path and performs an
 *   internal byte echo so RX/TX can be isolated and validated.
 *
 * Why this block matters:
 * - It is the main point where the same functional core can be reused under
 *   both the Tiny Tapeout wrapper and the ULX3S wrapper.
 */
`default_nettype none

/*
** See build options:
**   `define FORCE_DEEP_LOOPBACK
*/


module uart_trng_ascii_core
#(
    parameter [31:0] CLOCK_HZ  = 32'd25000000,
    parameter [31:0] UART_BAUD = 32'd115200
)
(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       uart_rx_i,
    output wire       uart_tx_o,

    output wire [7:0] reg_ctrl_o,
    output wire [7:0] reg_src_o,
    output wire [7:0] reg_div_o,
    output wire [7:0] reg_mode_o,
    output wire [7:0] reg_oscen_o,

    output wire [7:0] reg_status_o,
    output wire [7:0] reg_rawlo_o,
    output wire [7:0] reg_rawhi_o,
    output wire       trng_bit_o
);

    /* UART receive side: decoded byte plus one-cycle valid pulse. */
    wire [7:0] rx_byte;
    wire       rx_valid;

    /* UART transmit side: byte, launch pulse, and busy indication. */
    wire [7:0] tx_byte;
    wire       tx_start;
    wire       tx_busy;

    uart_rx_min
    #(
        .CLOCK_HZ(CLOCK_HZ),
        .UART_BAUD(UART_BAUD)
    )
    u_rx
    (
        .clk(clk),
        .rst_n(rst_n),
        .rx(uart_rx_i),
        .data_out(rx_byte),
        .data_valid(rx_valid)
    );

    uart_tx_min
    #(
        .CLOCK_HZ(CLOCK_HZ),
        .UART_BAUD(UART_BAUD)
    )
    u_tx
    (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(tx_byte),
        .start(tx_start),
        .tx(uart_tx_o),
        .busy(tx_busy)
    );

`ifdef FORCE_DEEP_LOOPBACK
    /*
     * Deep internal loopback mode:
     * - Meant to validate uart_rx_min and uart_tx_min in isolation.
     * - A received byte is sent straight back out when TX is idle.
     * - The register outputs become simple debug/status placeholders.
     *
     * This should not be combined with top-level FORCE_LOOPBACK, because then
     * the observed behavior would no longer reflect the internal echo path.
     */
    `ifdef FORCE_LOOPBACK
        MODULE_FORCE_LOOPBACK_MUST_NOT_BE_ENABLED_WITH_FORCE_DEEP_LOOPBACK u_stop ();
    `endif

    reg  [7:0] tx_byte_r;
    reg        tx_start_r;
    reg        rx_valid_d;

    reg  [7:0] pending_byte_r;
    reg        pending_valid_r;
    reg        overflow_r;

    reg  [7:0] reg_status_r;
    reg  [7:0] reg_rawlo_r;
    reg  [7:0] reg_rawhi_r;
    reg        trng_bit_r;

    /* Pulse detect so a received byte is echoed exactly once. */
    wire       rx_valid_pulse;

    /* Placeholder config outputs in loopback mode. */
    wire [7:0] reg_ctrl;
    wire [7:0] reg_src;
    wire [7:0] reg_div;
    wire [7:0] reg_mode;
    wire [7:0] reg_oscen;

    /* Debug/status outputs in loopback mode. */
    wire [7:0] reg_status;
    wire [7:0] reg_rawlo;
    wire [7:0] reg_rawhi;
    wire       trng_bit;

    assign rx_valid_pulse = rx_valid && !rx_valid_d;

    assign tx_byte  = tx_byte_r;
    assign tx_start = tx_start_r;

    assign reg_ctrl  = 8'h00;
    assign reg_src   = 8'h00;
    assign reg_div   = 8'h10;
    assign reg_mode  = 8'h00;
    assign reg_oscen = 8'h01;

    assign reg_status = reg_status_r;
    assign reg_rawlo  = reg_rawlo_r;
    assign reg_rawhi  = reg_rawhi_r;
    assign trng_bit   = trng_bit_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_valid_d      <= 1'b0;
            tx_byte_r       <= 8'h00;
            tx_start_r      <= 1'b0;
            pending_byte_r  <= 8'h00;
            pending_valid_r <= 1'b0;
            overflow_r      <= 1'b0;
            reg_status_r    <= 8'h00;
            reg_rawlo_r     <= 8'h00;
            reg_rawhi_r     <= 8'h00;
            trng_bit_r      <= 1'b0;
        end else begin
            rx_valid_d <= rx_valid;
            tx_start_r <= 1'b0;

            /*
             * Pack a few useful live debug indicators:
             * bit0 = raw UART RX input level at this clock
             * bit1 = decoded receive-byte pulse
             * bit2 = local TX start pulse
             * bit3 = TX busy
             * bit4 = pending byte waiting for TX
             * bit5 = loopback overflow/drop occurred
             */
            reg_status_r[0]   <= uart_rx_i;
            reg_status_r[1]   <= rx_valid;
            reg_status_r[2]   <= tx_start_r;
            reg_status_r[3]   <= tx_busy;
            reg_status_r[4]   <= pending_valid_r;
            reg_status_r[5]   <= overflow_r;
            reg_status_r[7:6] <= 2'b00;

            if (rx_valid_pulse) begin
                if (!pending_valid_r) begin
                    pending_byte_r  <= rx_byte;
                    pending_valid_r <= 1'b1;
                    reg_rawlo_r     <= rx_byte;
                    reg_rawhi_r     <= rx_byte;
                    trng_bit_r      <= rx_byte[0];
                end else begin
                    overflow_r <= 1'b1;
                end
            end

            if (!tx_busy && pending_valid_r) begin
                tx_byte_r       <= pending_byte_r;
                tx_start_r      <= 1'b1;
                pending_valid_r <= 1'b0;
            end
        end
    end
`else

    /*
     * Normal system mode:
     * - trng_cfg_ascii_core interprets UART command bytes.
     * - trng_stub supplies readable status and sample bytes.
     */
    wire [7:0] reg_ctrl;
    wire [7:0] reg_src;
    wire [7:0] reg_div;
    wire [7:0] reg_mode;
    wire [7:0] reg_oscen;

    wire [7:0] reg_status;
    wire [7:0] reg_rawlo;
    wire [7:0] reg_rawhi;
    wire       trng_bit;

    trng_cfg_ascii_core u_cfg
    (
        .clk(clk),
        .rst_n(rst_n),

        .rx_byte(rx_byte),
        .rx_valid(rx_valid),

        .tx_byte(tx_byte),
        .tx_start(tx_start),
        .tx_busy(tx_busy),

        .reg_ctrl(reg_ctrl),
        .reg_src(reg_src),
        .reg_div(reg_div),
        .reg_mode(reg_mode),
        .reg_oscen(reg_oscen),

        .reg_status(reg_status),
        .reg_rawlo(reg_rawlo),
        .reg_rawhi(reg_rawhi)
    );

    trng_stub u_trng
    (
        .clk(clk),
        .rst_n(rst_n),
        .reg_ctrl(reg_ctrl),
        .reg_src(reg_src),
        .reg_div(reg_div),
        .reg_mode(reg_mode),
        .reg_oscen(reg_oscen[0]),
        .reg_status(reg_status),
        .reg_rawlo(reg_rawlo),
        .reg_rawhi(reg_rawhi),
        .trng_bit(trng_bit)
    );

`endif

    /* Re-export selected internals to the outer wrappers for debug/visibility. */
    assign reg_ctrl_o   = reg_ctrl;
    assign reg_src_o    = reg_src;
    assign reg_div_o    = reg_div;
    assign reg_mode_o   = reg_mode;
    assign reg_oscen_o  = reg_oscen;

    assign reg_status_o = reg_status;
    assign reg_rawlo_o  = reg_rawlo;
    assign reg_rawhi_o  = reg_rawhi;
    assign trng_bit_o   = trng_bit;

endmodule

`default_nettype wire
