/*
 * Copyright (c) 2026 gojimmypi
 * SPDX-License-Identifier: Apache-2.0
 *
 * See ATTRIBUTION.md for third-party sources and credits.
 *
 * file: esp32_prog_ctrl.v
 *
 * ESP32 programming and boot-control helper for the ULX3S wrapper.
 *
 * This module controls ESP32 EN and GPIO0. It supports three build modes:
 *
 *   1. ESP32_BOOT_CONTROL_ENABLED undefined:
 *      Keep ESP32 enabled and in normal flash boot mode.
 *
 *   2. ESP32_BOOT_CONTROL_ENABLED defined, ESP32_BOOT_RTS_DTR_ENABLED undefined:
 *      Manual button control. btn_reset_n drives ESP32 EN. The ULX3S
 *      B1/F1 boot button input is normalized internally before driving
 *      ESP32 GPIO0.
 *
 *   3. ESP32_BOOT_CONTROL_ENABLED and ESP32_BOOT_RTS_DTR_ENABLED defined:
 *      Use FTDI active-low DTR/RTS signals for hands-off esptool style
 *      programming only when select_usb_uart is asserted. Manual buttons
 *      are also combined as active-low requests, so BTN0/PWR can reset and
 *      B1/F1 can force ESP32 GPIO0 low.
 *
 *      This follows the common ULX3S ESP32 passthru mapping:
 *
 *          DTR RTS -> EN GPIO0
 *           1   1      1   1
 *           0   0      1   1
 *           1   0      0   1
 *           0   1      1   0
 */
`default_nettype none
`timescale 1ns/1ps

/* Ensure the file is included in Makefile and HAS_ESP32_PROG_CTRL is defined. */

module esp32_prog_ctrl
(
    input  wire clk,
    input  wire btn_reset_n,
    input  wire btn_boot_n,

    input  wire ftdi_nrts,
    input  wire ftdi_ndtr,

    input  wire select_usb_uart,

    output wire wifi_en,
    output wire wifi_gpio0
);

`ifdef ESP32_BOOT_CONTROL_ENABLED
    /*
     * On this ULX3S build, btn[1] has been observed to behave active-high
     * for the manual ESP32 BOOT request:
     *
     *     btn_boot_n == 1: B1/F1 pressed, request GPIO0 low
     *     btn_boot_n == 0: B1/F1 released, release GPIO0 high
     *
     * Keep the port name for compatibility with top_ulx3s.v, but normalize
     * it here to the active-high ESP32 GPIO0 released value.
     */
    wire btn_boot_released;

    assign btn_boot_released = ~btn_boot_n;

    `ifdef ESP32_BOOT_RTS_DTR_ENABLED
        /*
         * Hands-off ESP32 programming.
         *
         * EN/reset uses the standard ULX3S passthru mapping.
         *
         * GPIO0 does not directly follow DTR forever. Instead, when the
         * passthru mapping requests GPIO0 low, hold GPIO0 low for a limited
         * boot-entry window, then release it high even if the host keeps DTR
         * asserted. This prevents PuTTY/idf_monitor from trapping the ESP32
         * in ROM download mode after flashing.
         */
        localparam [23:0] ESP32_POST_CONFIG_RESET_CLKS = 24'd1_250_000;
        localparam [23:0] ESP32_GPIO0_LOW_CLKS         = 24'd5_000_000;

        reg [23:0] esp32_reset_delay = 24'd0;
        reg [23:0] esp32_gpio0_low_count = 24'd0;
        reg        ftdi_gpio0_request_low_d = 1'b0;

        wire [1:0] prog_in;
        wire [1:0] prog_out;

        wire fpga_reset_done;
        wire ftdi_gpio0_request_low;
        wire ftdi_gpio0_request_start;
        wire ftdi_gpio0_low_active;

        assign prog_in[1] = ftdi_ndtr;
        assign prog_in[0] = ftdi_nrts;

        assign prog_out = prog_in == 2'b10 ? 2'b01 :
                          prog_in == 2'b01 ? 2'b10 :
                                              2'b11;

        assign fpga_reset_done = esp32_reset_delay == ESP32_POST_CONFIG_RESET_CLKS;

        /*
         * prog_out[0] == 0 is the passthru request for ESP32 GPIO0 low.
         * Convert that level request into a one-shot timed low pulse.
         */
        assign ftdi_gpio0_request_low = select_usb_uart & ~prog_out[0];
        assign ftdi_gpio0_request_start = ftdi_gpio0_request_low & ~ftdi_gpio0_request_low_d;
        assign ftdi_gpio0_low_active = esp32_gpio0_low_count != 24'd0;

        always @(posedge clk) begin
            ftdi_gpio0_request_low_d <= ftdi_gpio0_request_low;

            if (esp32_reset_delay != ESP32_POST_CONFIG_RESET_CLKS) begin
                esp32_reset_delay <= esp32_reset_delay + 24'd1;
            end

            if (ftdi_gpio0_request_start) begin
                esp32_gpio0_low_count <= ESP32_GPIO0_LOW_CLKS;
            end
            else if (esp32_gpio0_low_count != 24'd0) begin
                esp32_gpio0_low_count <= esp32_gpio0_low_count - 24'd1;
            end
        end

        assign wifi_en = fpga_reset_done & (select_usb_uart ? prog_out[1] : 1'b1) & btn_reset_n;
        assign wifi_gpio0 = (ftdi_gpio0_low_active ? 1'b0 : 1'b1) & btn_boot_released;
    `else
        /* Manual ESP32 reset and boot-mode control. */
        assign wifi_en    = btn_reset_n;
        assign wifi_gpio0 = btn_boot_released;
    `endif
`else
    /* Keep ESP32 enabled and in normal flash boot mode. */
    assign wifi_en    = 1'b1;
    assign wifi_gpio0 = 1'b1;
`endif

endmodule /* esp32_prog_ctrl */

`default_nettype wire
