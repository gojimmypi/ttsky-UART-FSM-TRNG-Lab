/*
 * Copyright (c) 2026 gojimmypi
 * SPDX-License-Identifier: Apache-2.0
 *
 * See ATTRIBUTION.md for third-party sources and credits.
 *
 * file: esp32_uart_auto_mux.v
 *
 * ESP32 UART programming path selector for the ULX3S wrapper.
 *
 * Reset behavior:
 *   - ESP32 RX defaults to the external UART TX path.
 *   - No programming method is locked yet.
 *
 * Lock behavior:
 *   - FTDI RTS/DTR programming activity locks the onboard FTDI USB UART
 *     path until FPGA reset.
 *   - If no FTDI programming activity is present, a manual ESP32 boot-mode
 *     request locks the external UART programming path until FPGA reset.
 *
 * Normal external UART activity does not lock the mux. This avoids treating
 * TT UART/TRNG register testing as ESP32 flashing.
 */
`default_nettype none
`timescale 1ns/1ps

module esp32_uart_auto_mux
(
    input  wire clk,
    input  wire rst_n,

    input  wire ftdi_txd,
    output wire ftdi_rxd,

    input  wire ftdi_ndtr,
    input  wire ftdi_nrts,

    input  wire ext_uart_txd,
    output wire ext_uart_rxd,

    input  wire external_prog_request,

    input  wire wifi_txd,
    output wire wifi_rxd,

    output wire select_usb_uart,
    output wire select_external_uart,
    output wire uart_select_locked
);

    localparam [1:0] SEL_UNLOCKED = 2'd0;
    localparam [1:0] SEL_EXTERNAL = 2'd1;
    localparam [1:0] SEL_USB      = 2'd2;

    reg [1:0] select_state;

    reg ftdi_ndtr_d1;
    reg ftdi_ndtr_d2;
    reg ftdi_nrts_d1;
    reg ftdi_nrts_d2;

    reg external_prog_request_d1;
    reg external_prog_request_d2;

    wire ftdi_prog_state;
    wire external_prog_state;

    assign ftdi_prog_state =
        ((ftdi_ndtr_d2 == 1'b1) && (ftdi_nrts_d2 == 1'b0)) ||
        ((ftdi_ndtr_d2 == 1'b0) && (ftdi_nrts_d2 == 1'b1));

    assign external_prog_state = external_prog_request_d2;

    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            ftdi_ndtr_d1 <= 1'b1;
            ftdi_ndtr_d2 <= 1'b1;
            ftdi_nrts_d1 <= 1'b1;
            ftdi_nrts_d2 <= 1'b1;

            external_prog_request_d1 <= 1'b0;
            external_prog_request_d2 <= 1'b0;

            select_state <= SEL_UNLOCKED;
        end else begin
            ftdi_ndtr_d1 <= ftdi_ndtr;
            ftdi_ndtr_d2 <= ftdi_ndtr_d1;
            ftdi_nrts_d1 <= ftdi_nrts;
            ftdi_nrts_d2 <= ftdi_nrts_d1;

            external_prog_request_d1 <= external_prog_request;
            external_prog_request_d2 <= external_prog_request_d1;

            case (select_state)
                SEL_UNLOCKED: begin
                    if (ftdi_prog_state == 1'b1) begin
                        select_state <= SEL_USB;
                    end else if (external_prog_state == 1'b1) begin
                        select_state <= SEL_EXTERNAL;
                    end else begin
                        select_state <= SEL_UNLOCKED;
                    end
                end

                SEL_EXTERNAL: begin
                    select_state <= SEL_EXTERNAL;
                end

                SEL_USB: begin
                    select_state <= SEL_USB;
                end

                default: begin
                    select_state <= SEL_UNLOCKED;
                end
            endcase
        end
    end

    assign select_usb_uart =
        (select_state == SEL_USB);

    assign select_external_uart =
        (select_state == SEL_EXTERNAL);

    assign uart_select_locked =
        (select_state != SEL_UNLOCKED);

    assign wifi_rxd =
        select_usb_uart ? ftdi_txd : ext_uart_txd;

    assign ftdi_rxd =
        select_usb_uart ? wifi_txd : 1'b1;

    assign ext_uart_rxd =
        select_external_uart ? wifi_txd : 1'b1;

endmodule /* esp32_uart_auto_mux */

`default_nettype wire
