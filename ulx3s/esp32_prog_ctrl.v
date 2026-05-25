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
        wire [1:0] prog_in;
        wire [1:0] prog_out;

        assign prog_in[1] = ftdi_ndtr;
        assign prog_in[0] = ftdi_nrts;

        assign prog_out = prog_in == 2'b10 ? 2'b01 :
                          prog_in == 2'b01 ? 2'b10 :
                                              2'b11;

        wire ftdi_wifi_en;
        wire ftdi_wifi_gpio0;

        assign ftdi_wifi_en = select_usb_uart ? prog_out[1] : 1'b1;
        assign ftdi_wifi_gpio0 = select_usb_uart ? prog_out[0] : 1'b1;

        assign wifi_en = ftdi_wifi_en & btn_reset_n;
        assign wifi_gpio0 = ftdi_wifi_gpio0 & btn_boot_released;
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
