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
         * The FTDI RTS/DTR inputs are not passed directly to ESP32 EN/GPIO0.
         * They are treated as requests. The FPGA generates clean pulses:
         *
         *     - bootloader entry: EN low with GPIO0 low, then EN high with
         *       GPIO0 still low briefly, then GPIO0 high.
         *
         *     - app reset: EN low with GPIO0 high, then EN high.
         *
         * This prevents PuTTY/idf_monitor DTR or RTS state from trapping the
         * ESP32 in ROM download mode.
         */

        /*
         * At 25 MHz:
         *
         *     ESP32_POST_CONFIG_RESET_CLKS = 50 ms   (1,250,000 ticks)
         *     ESP32_RESET_LOW_CLKS         = 100 ms  (2,500,000 ticks)
         *     ESP32_GPIO0_HOLD_CLKS        = 100 ms  (2,500,000 ticks)
         *     ESP32_BOOT_INHIBIT_CLKS      = 30 s    (750,000,000 ticks)
         *
         * POST_CONFIG_RESET holds ESP32 EN low after FPGA configuration so the
         * ESP32 starts from a known state after FPGA-controlled pins are valid.
         *
         * RESET_LOW is the generated ESP32 reset pulse width used by the FSM.
         *
         * GPIO0_HOLD keeps GPIO0 low briefly after EN is released during
         * bootloader entry, giving the ESP32 time to sample the boot strap.
         *
         * BOOT_INHIBIT prevents later RTS/DTR activity from causing another
         * bootloader-entry sequence after programming has started. This lets
         * esptool's final hard reset restart the ESP32 app instead of returning
         * to ROM download mode.
         */
        localparam [29:0] ESP32_POST_CONFIG_RESET_CLKS = 30'd1_250_000;
        localparam [29:0] ESP32_RESET_LOW_CLKS         = 30'd2_500_000;
        localparam [29:0] ESP32_GPIO0_HOLD_CLKS        = 30'd2_500_000;
        localparam [29:0] ESP32_BOOT_INHIBIT_CLKS      = 30'd750_000_000;

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
        reg [29:0] esp32_boot_inhibit_count = 30'd0;
        reg  [2:0] esp32_state              = ESP32_STATE_RUN;

        reg ftdi_reset_level_d = 1'b0;
        reg boot_armed         = 1'b0;

        wire fpga_reset_done;          /* FPGA startup delay is complete; ESP32 EN may be released. */

        wire ftdi_boot_level;          /* Active-high request for GPIO0 low, decoded from nDTR low and nRTS high. */
        wire ftdi_reset_level;         /* Active-high reset request, decoded from nDTR high and nRTS low. */
        wire ftdi_reset_start;         /* Start of a decoded reset request. */

        wire ftdi_boot_request;        /* Request a controlled GPIO0-low bootloader-entry reset. */
        wire ftdi_app_reset_request;   /* Request a GPIO0-high app reset after programming. */
        wire boot_inhibit_active;      /* Block repeated bootloader entry after the first boot pulse. */

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
        assign ftdi_reset_start = (ftdi_reset_level & ~ftdi_reset_level_d);

        assign boot_inhibit_active = (esp32_boot_inhibit_count != 30'd0);

        /*
         * A bootloader entry requires the host to request boot mode first,
         * then request reset. PuTTY/idf_monitor opening the port with both
         * nDTR and nRTS asserted low must not start bootloader entry.
         */
        assign ftdi_boot_request = (boot_armed & ftdi_reset_start & ~boot_inhibit_active);

        /*
         * During the inhibit window, reset requests are app resets only:
         * EN low with GPIO0 high. This lets esptool's final hard reset start
         * the flashed application.
         */
        assign ftdi_app_reset_request = (ftdi_reset_start & boot_inhibit_active);

        assign state_boot_reset = (esp32_state == ESP32_STATE_BOOT_RESET);
        assign state_boot_hold  = (esp32_state == ESP32_STATE_BOOT_HOLD);
        assign state_app_reset  = (esp32_state == ESP32_STATE_APP_RESET);

        always @(posedge clk) begin
            ftdi_reset_level_d <= ftdi_reset_level;

            if (esp32_post_config_count != ESP32_POST_CONFIG_RESET_CLKS) begin
                esp32_post_config_count <= esp32_post_config_count + 30'd1;
            end

            if (esp32_boot_inhibit_count != 30'd0) begin
                esp32_boot_inhibit_count <= esp32_boot_inhibit_count - 30'd1;
            end

            if (ftdi_boot_level && !boot_inhibit_active) begin
                boot_armed <= 1'b1;
            end

            case (esp32_state)
                ESP32_STATE_RUN: begin
                    esp32_state_count <= 30'd0;

                    if (ftdi_boot_request) begin
                        esp32_state              <= ESP32_STATE_BOOT_RESET;
                        esp32_state_count        <= ESP32_RESET_LOW_CLKS;
                        esp32_boot_inhibit_count <= ESP32_BOOT_INHIBIT_CLKS;
                        boot_armed               <= 1'b0;
                    end
                    else if (ftdi_app_reset_request) begin
                        esp32_state              <= ESP32_STATE_APP_RESET;
                        esp32_state_count        <= ESP32_RESET_LOW_CLKS;
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

                ESP32_STATE_APP_RESET: begin
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
                    boot_armed                   <= 1'b0;
                end
            endcase

            if (!select_usb_uart) begin
                esp32_state                      <= ESP32_STATE_RUN;
                esp32_state_count                <= 30'd0;
                boot_armed                       <= 1'b0;
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
         * The reset button always forces EN low. The boot button can still
         * force GPIO0 low, but is not required for programming.
         */
        assign wifi_en = fpga_reset_done &
                         ~state_boot_reset &
                         ~state_app_reset &
                         btn_reset_n;

        assign wifi_gpio0 = ~(state_boot_reset | state_boot_hold) &
                            btn_boot_released;
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
