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
 *      RTS/DTR are decoded using the common ULX3S passthru meanings, but
 *      they are not passed directly to ESP32 EN/GPIO0. The FPGA generates
 *      clean EN/GPIO0 pulses so terminal programs cannot leave the ESP32
 *      trapped in ROM download mode.
 *
 *      Decoded active-low FTDI meanings:
 *
 *          nDTR nRTS -> request
 *            1    1     none / normal
 *            0    0     none / normal, ignored for PuTTY/idf_monitor safety
 *            1    0     reset request
 *            0    1     boot GPIO0 request
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
         * Do not remember a GPIO0-low request and apply it to a later reset.
         * A normal reset must always release GPIO0 high.
         *
         * Bootloader entry is recognized only as the esptool sequence:
         *
         *     1. reset request:       nDTR=1, nRTS=0
         *     2. boot release request nDTR=0, nRTS=1 while that reset is active
         *
         * A standalone nDTR=0, nRTS=1 state is ignored. This prevents
         * idf_monitor or terminal open/close side effects from arming a later
         * reset into ROM download mode.
         */

        /*
         * At 25 MHz:
         *
         *     ESP32_POST_CONFIG_RESET_CLKS = 50 ms   (1,250,000 ticks)
         *     ESP32_RESET_LOW_CLKS         = 100 ms  (2,500,000 ticks)
         *     ESP32_GPIO0_HOLD_CLKS        = 100 ms  (2,500,000 ticks)
         */
        localparam [29:0] ESP32_POST_CONFIG_RESET_CLKS = 30'd1_250_000;
        localparam [29:0] ESP32_RESET_LOW_CLKS         = 30'd2_500_000;
        localparam [29:0] ESP32_GPIO0_HOLD_CLKS        = 30'd2_500_000;

        /* We have 4 possible boot states for the ESP32. */
        /* BOOT_RESET: EN low,  GPIO0 low  */
        /* APP_RESET:  EN low,  GPIO0 high */
        /* BOOT_HOLD:  EN high, GPIO0 low  */
        /* RUN:        EN high, GPIO0 high */
        localparam [2:0] ESP32_STATE_BOOT_RESET = 3'd0;
        localparam [2:0] ESP32_STATE_APP_RESET  = 3'd1;
        localparam [2:0] ESP32_STATE_BOOT_HOLD  = 3'd2;
        localparam [2:0] ESP32_STATE_RUN        = 3'd3;

        reg [29:0] esp32_post_config_count  = 30'd0;
        reg [29:0] esp32_state_count        = 30'd0;
        reg  [2:0] esp32_state              = ESP32_STATE_RUN;

        reg ftdi_reset_active               = 1'b0;

        wire fpga_reset_done;          /* FPGA startup delay is complete; ESP32 EN may be released. */

        wire ftdi_boot_level;          /* Active-high request for GPIO0 low, decoded from nDTR low and nRTS high. */
        wire ftdi_reset_level;         /* Active-high reset request, decoded from nDTR high and nRTS low. */

        wire state_boot_reset;         /* FSM is holding EN low and GPIO0 low. */
        wire state_boot_hold;          /* FSM has released EN and is briefly holding GPIO0 low. */
        wire state_app_reset;          /* FSM is holding EN low and GPIO0 high. */

        assign fpga_reset_done = (esp32_post_config_count == ESP32_POST_CONFIG_RESET_CLKS);

        /*
         * Decode the original ULX3S active-low FTDI passthru meanings into
         * FPGA requests. Do not treat nDTR low + nRTS low as bootloader mode;
         * terminal programs may assert both when opening the port.
         *
         *     ftdi_ndtr ftdi_nrts -> request
         *          1         1       none
         *          0         0       none
         *          1         0       reset request
         *          0         1       boot/GPIO0 request
         */
        assign ftdi_boot_level  = (select_usb_uart & ~ftdi_ndtr &  ftdi_nrts);
        assign ftdi_reset_level = (select_usb_uart &  ftdi_ndtr & ~ftdi_nrts);

        assign state_boot_reset = (esp32_state == ESP32_STATE_BOOT_RESET);
        assign state_boot_hold  = (esp32_state == ESP32_STATE_BOOT_HOLD);
        assign state_app_reset  = (esp32_state == ESP32_STATE_APP_RESET);

        always @(posedge clk) begin
            if (esp32_post_config_count != ESP32_POST_CONFIG_RESET_CLKS) begin
                esp32_post_config_count <= esp32_post_config_count + 30'd1;
            end

            case (esp32_state)
                ESP32_STATE_RUN: begin
                    esp32_state_count            <= 30'd0;
                    ftdi_reset_active            <= 1'b0;

                    if (ftdi_reset_level) begin
                        esp32_state              <= ESP32_STATE_APP_RESET;
                        esp32_state_count        <= ESP32_RESET_LOW_CLKS;
                        ftdi_reset_active        <= 1'b1;
                    end
                end

                ESP32_STATE_APP_RESET: begin
                    if (ftdi_reset_active && ftdi_boot_level) begin
                        esp32_state              <= ESP32_STATE_BOOT_RESET;
                        esp32_state_count        <= ESP32_RESET_LOW_CLKS;
                        ftdi_reset_active        <= 1'b0;
                    end
                    else if (esp32_state_count != 30'd0) begin
                        esp32_state_count        <= esp32_state_count - 30'd1;
                    end
                    else begin
                        esp32_state              <= ESP32_STATE_RUN;
                        ftdi_reset_active        <= 1'b0;
                    end
                end

                ESP32_STATE_BOOT_RESET: begin
                    if (esp32_state_count != 30'd0) begin
                        esp32_state_count        <= esp32_state_count - 30'd1;
                    end
                    else begin
                        esp32_state              <= ESP32_STATE_BOOT_HOLD;
                        esp32_state_count        <= ESP32_GPIO0_HOLD_CLKS;
                    end
                end

                ESP32_STATE_BOOT_HOLD: begin
                    if (esp32_state_count != 30'd0) begin
                        esp32_state_count        <= esp32_state_count - 30'd1;
                    end
                    else begin
                        esp32_state              <= ESP32_STATE_RUN;
                    end
                end

                default: begin
                    esp32_state                  <= ESP32_STATE_RUN;
                    esp32_state_count            <= 30'd0;
                    ftdi_reset_active            <= 1'b0;
                end
            endcase

            if (!btn_reset_n) begin
                esp32_state                      <= btn_boot_released ?
                                                        ESP32_STATE_APP_RESET :
                                                        ESP32_STATE_BOOT_RESET;
                esp32_state_count                <= ESP32_RESET_LOW_CLKS;
                ftdi_reset_active                <= 1'b0;
            end

            if (!select_usb_uart) begin
                esp32_state                      <= ESP32_STATE_RUN;
                esp32_state_count                <= 30'd0;
                ftdi_reset_active                <= 1'b0;
            end
        end

        /*
         * Output rules:
         *
         *     BOOT_RESET: EN low,  GPIO0 low
         *     BOOT_HOLD:  EN high, GPIO0 low
         *     APP_RESET:  EN low,  GPIO0 high
         *     RUN:        EN high, GPIO0 high
         *
         * The reset button always forces app reset behavior. In USB programming
         * mode, the boot button is intentionally not combined into GPIO0.
         */
        assign wifi_en = fpga_reset_done &
                         ~state_boot_reset &
                         ~state_app_reset &
                         btn_reset_n;

        assign wifi_gpio0 = ~(state_boot_reset | state_boot_hold);

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
