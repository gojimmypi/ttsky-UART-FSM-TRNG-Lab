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
        localparam [29:0] ESP32_POST_CONFIG_RESET_CLKS = 30'd1_250_000;
        localparam [29:0] ESP32_RESET_LOW_CLKS         = 30'd2_500_000;
        localparam [29:0] ESP32_GPIO0_HOLD_CLKS        = 30'd2_500_000;
        localparam [29:0] ESP32_BOOT_INHIBIT_CLKS      = 30'd750_000_000;

        localparam [2:0] ESP32_STATE_IDLE              = 3'd0;
        localparam [2:0] ESP32_STATE_BOOT_RESET        = 3'd1;
        localparam [2:0] ESP32_STATE_BOOT_HOLD         = 3'd2;
        localparam [2:0] ESP32_STATE_APP_RESET         = 3'd3;

        reg [29:0] esp32_post_config_count = 30'd0;
        reg [29:0] esp32_state_count = 30'd0;
        reg [29:0] esp32_boot_inhibit_count = 30'd0;
        reg [2:0]  esp32_state = ESP32_STATE_IDLE;

        reg ftdi_nrts_d = 1'b1;
        reg ftdi_ndtr_d = 1'b1;

        wire fpga_reset_done;
        wire ftdi_rts_asserted;
        wire ftdi_dtr_asserted;
        wire ftdi_rts_falling;
        wire ftdi_boot_request;
        wire ftdi_app_reset_request;
        wire boot_inhibit_active;

        wire state_boot_reset;
        wire state_boot_hold;
        wire state_app_reset;

        assign fpga_reset_done = esp32_post_config_count == ESP32_POST_CONFIG_RESET_CLKS;

        /*
         * Active-low FTDI modem-control inputs.
         */
        assign ftdi_rts_asserted = select_usb_uart & ~ftdi_nrts;
        assign ftdi_dtr_asserted = select_usb_uart & ~ftdi_ndtr;
        assign ftdi_rts_falling = select_usb_uart & ftdi_nrts_d & ~ftdi_nrts;

        assign boot_inhibit_active = esp32_boot_inhibit_count != 30'd0;

        /*
         * Treat "DTR low and RTS low" as a bootloader-entry request, but only
         * when not inhibited. During inhibit, the same RTS activity becomes an
         * app reset with GPIO0 high.
         */
        assign ftdi_boot_request = ftdi_dtr_asserted & ftdi_rts_asserted & ~boot_inhibit_active;
//      assign ftdi_app_reset_request = ftdi_rts_falling & (boot_inhibit_active | ~ftdi_dtr_asserted);
        assign ftdi_app_reset_request = ftdi_rts_falling & boot_inhibit_active;

        assign state_boot_reset = esp32_state == ESP32_STATE_BOOT_RESET;
        assign state_boot_hold = esp32_state == ESP32_STATE_BOOT_HOLD;
        assign state_app_reset = esp32_state == ESP32_STATE_APP_RESET;

        always @(posedge clk) begin
            ftdi_nrts_d <= ftdi_nrts;
            ftdi_ndtr_d <= ftdi_ndtr;

            if (esp32_post_config_count != ESP32_POST_CONFIG_RESET_CLKS) begin
                esp32_post_config_count <= esp32_post_config_count + 30'd1;
            end

            if (esp32_boot_inhibit_count != 30'd0) begin
                esp32_boot_inhibit_count <= esp32_boot_inhibit_count - 30'd1;
            end

            case (esp32_state)
                ESP32_STATE_IDLE: begin
                    esp32_state_count <= 30'd0;

                    if (ftdi_boot_request) begin
                        esp32_state <= ESP32_STATE_BOOT_RESET;
                        esp32_state_count <= ESP32_RESET_LOW_CLKS;
                        esp32_boot_inhibit_count <= ESP32_BOOT_INHIBIT_CLKS;
                    end
                    else if (ftdi_app_reset_request) begin
                        esp32_state <= ESP32_STATE_APP_RESET;
                        esp32_state_count <= ESP32_RESET_LOW_CLKS;
                    end
                end

                ESP32_STATE_BOOT_RESET: begin
                    if (esp32_state_count != 30'd0) begin
                        esp32_state_count <= esp32_state_count - 30'd1;
                    end
                    else begin
                        esp32_state <= ESP32_STATE_BOOT_HOLD;
                        esp32_state_count <= ESP32_GPIO0_HOLD_CLKS;
                    end
                end

                ESP32_STATE_BOOT_HOLD: begin
                    if (esp32_state_count != 30'd0) begin
                        esp32_state_count <= esp32_state_count - 30'd1;
                    end
                    else begin
                        esp32_state <= ESP32_STATE_IDLE;
                    end
                end

                ESP32_STATE_APP_RESET: begin
                    if (esp32_state_count != 30'd0) begin
                        esp32_state_count <= esp32_state_count - 30'd1;
                    end
                    else begin
                        esp32_state <= ESP32_STATE_IDLE;
                    end
                end

                default: begin
                    esp32_state <= ESP32_STATE_IDLE;
                    esp32_state_count <= 30'd0;
                end
            endcase

            if (!select_usb_uart) begin
                esp32_state <= ESP32_STATE_IDLE;
                esp32_state_count <= 30'd0;
            end
        end

        /*
         * Output rules:
         *
         *     BOOT_RESET: EN low,  GPIO0 low
         *     BOOT_HOLD:  EN high, GPIO0 low
         *     APP_RESET:  EN low,  GPIO0 high
         *     IDLE:       EN high, GPIO0 high
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
