/*
 * Copyright (c) 2026 gojimmypi
 * SPDX-License-Identifier: Apache-2.0
 *
 * See ATTRIBUTION.md for third-party sources and credits.
 *
 * file: top_ulx3s.v
 *
 * This is a ULX3S-specific wrapper for the TT module defined in /project.v
 * It maps the standard TT pin interface to the actual pins on the ULX3S board, 
 * and includes some simple logic to synchronize the UART RX signal and 
 * optionally loop back the UART TX for testing.
 */
`default_nettype none
`timescale 1ns/1ps

`define ESP32_BOOT_CONTROL_ENABLED
`define ULX3S_SPI_ENABLED
//`define ESP32_BOOT_RTS_DTS_ENABLED

module top_ulx3s (
    input  wire        clk_25mhz,
    input  wire [6:0]  btn,
    output wire [7:0]  led,

    /* External PMOD-style UART pins. */
    input  wire        gp0,
    output wire        gp1,

    /* USB FTDI UART. */
    output wire        ftdi_rxd,
    input  wire        ftdi_txd,

`ifdef ULX3S_SPI_ENABLED
    /* Instead of editing reference lpf, we'll use the existing names for SPI. */
    input  wire wifi_gpio14,  /* ESP32 PIN_NUM_CLK  14, wire spi_sck   */
    input  wire wifi_gpio15,  /* ESP32 PIN_NUM_MOSI 15, wire spi_mosi  */
    input  wire wifi_gpio13,  /* ESP32 PIN_NUM_CS   13, wire spi_cs_n */
    output wire wifi_gpio2,   /* ESP32 PIN_NUM_MISO  2, wire spi_miso  */
`endif

/* Experimental RTS/DTS to control ESP32 boot mode during serial programming.
 * See also ESP32_BOOT_CONTROL_ENABLED, below  */
`ifdef ESP32_BOOT_RTS_DTS_ENABLED
    input  wire        ftdi_nrts,
    input  wire        ftdi_ndtr,
`endif
    /* ESP32 UART and boot control. */
    output wire        wifi_rxd,
    input  wire        wifi_txd,
    output wire        wifi_en,
    output wire        wifi_gpio0,

    /* Keep board powered. */
    output wire        shutdown
); /* top_ulx3s input */

    wire [7:0] ui_in;
    wire [7:0] uio_in;
    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    wire rst_n;
    wire ena;

    reg uart_rx_meta;
    reg uart_rx_sync;

    wire uart_rx_pin;
    wire uart_tx_pin;

`ifdef ULX3S_SPI_ENABLED
    wire spi_sck;  /* ESP32 PIN_NUM_CLK  14 */
    wire spi_mosi; /* ESP32 PIN_NUM_MOSI 15 */
    wire spi_cs_n; /* ESP32 PIN_NUM_CS   13 */
    wire spi_miso; /* ESP32 PIN_NUM_MISO  2 */
`endif

    /* The BTN0 "PWR" on the ULX3S is used for reset. 
     * It is active-low, so we can connect it directly to rst_n. */
    assign rst_n = btn[0];

    assign ena   = 1'b1;

    `ifdef ESP32_BOOT_CONTROL_ENABLED
        /* If ESP32_BOOT_CONTROL_ENABLED is defined, BTN0 controls wifi_en and BTN1 controls wifi_gpio0 
         *
         * To RESET the ESP32 and start the running program in flash:
         *    Hold btn[1]
         *    Tap btn[0]
         *    Release btn[1] 
         *
         * To PROGRAM the ESP32 in flash:
         *    Hold btn[0]
         *      (begin flash upload)
         *    Release btn[0] when "Connecting..." is observed.
         * 
         * Should then see something like:
         *
         *   Chip is ESP32-D0WDQ6 (revision v1.0)
         *   Features: WiFi, BT, Dual Core, 240MHz, VRef calibration in efuse, Coding Scheme None
         *   Crystal is 40MHz
         *   Uploading stub...
         *   Running stub...
         *   Stub running...
         *   Changing baud rate to 460800
         *   Changed.
         */
        `ifdef ESP32_BOOT_RTS_DTS_ENABLED
            wire dtr;
            wire rts;

            wire en_auto;
            wire gpio0_auto;

            assign dtr = ~ftdi_ndtr;
            assign rts = ~ftdi_nrts;

            assign en_auto    = ~(rts & ~dtr);
            assign gpio0_auto = ~(dtr & ~rts);

            assign wifi_en    = en_auto;
            assign wifi_gpio0 = gpio0_auto;
        `else
            /* Current default: no RTS / DTS control */
            assign wifi_en    = btn[0];
            assign wifi_gpio0 = btn[1];
        `endif /* ESP32_BOOT_RTS_DTS_ENABLED */
    `else
        /* Keep ESP32 enabled and in normal boot mode. */
        assign wifi_en    = 1'b1;
        assign wifi_gpio0 = 1'b1;
    `endif /* ESP32_BOOT_CONTROL_ENABLED */

    /* Do not shut down ULX3S power. */
    assign shutdown = 1'b0;

    /*
     * UART source selection.
     *
     * Define ESP32_UART_ENABLED to connect the TT UART to the onboard ESP32.
     * Otherwise, keep using gp0/gp1 for the external UART path.
     */
    `ifdef ESP32_UART_ENABLED
        assign uart_rx_pin = wifi_txd;
        assign wifi_rxd    = uart_tx_pin;
        assign gp1         = uart_tx_pin;

        /* Mirror ESP32 TX to the USB FTDI RX pin for debug visibility. */
        assign ftdi_rxd = wifi_txd;

        wire unused_ftdi_txd;
        assign unused_ftdi_txd = ftdi_txd;
    `else
        `ifdef NO_ESP32_PASSTHRU_ENABLED
            /* The ULS3S US1 USB port is NOT connected to the ESP32 */
        `else
            /* Unless explicitly disabled or otherwise assigned, connect the ESP32 to the ULX3S port */
            assign uart_rx_pin = gp0;
            assign gp1         = uart_tx_pin;

            /* Leave USB FTDI connected to ESP32 when not using ESP32 for TT UART. (see above) */
            assign wifi_rxd = ftdi_txd;
            assign ftdi_rxd = wifi_txd;
        `endif
    `endif /* ESP32_UART_PASSTHRU_ENABLED */

    /* Optional UART support - enable by defining UART_ENABLED in your project.v */
    `ifdef UART_ENABLED
        /* See example UART: https://github.com/gojimmypi/ttsky-UART-FSM-TRNG-Lab */

        always @(posedge clk_25mhz) begin
            uart_rx_meta <= uart_rx_pin;
            uart_rx_sync <= uart_rx_meta;
        end

        // Map UART RX into TT input
        assign ui_in = {4'b0000, uart_rx_sync, 3'b000};

`ifdef ULX3S_SPI_ENABLED
        assign uio_in = {5'b00000, spi_cs_n, spi_mosi, spi_sck};
`else
        assign uio_in = 8'h00;
`endif
    `endif

    `ifdef ULX3S_SPI_ENABLED
        assign spi_sck    = wifi_gpio14;
        assign spi_mosi   = wifi_gpio15;
        assign spi_cs_n   = wifi_gpio13;

        `ifdef TEST_SPI_ZERO
            /* Board-level pin test before using the TT SPI implementation. */
            assign wifi_gpio2 = 1'b0;  /* ESP32 should return rx: 00 00 */
            // assign wifi_gpio2 = 1'b1;  /* ESP32 should return rx: FF FF */
        `else
            assign spi_miso   = uio_out[3];
            assign wifi_gpio2 = spi_miso;
        `endif
    `endif

    /*************************************************************************
     * Instantiate the main DUT from TT module in /project.v
     ************************************************************************/
    tt_um_gojimmypi_ttsky_UART_FSM_TRNG_Lab dut
    (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .ena(ena),
        .clk(clk_25mhz),
        .rst_n(rst_n)  // TODO - add a reset button and connect it here instead of hardcoding rst_n=1
    );

    /* Some optional UART loopback test for development only */
    `ifdef FORCE_LOOPBACK
        // Loopback UART TX to RX for testing
        initial $display("FORCE_LOOPBACK ENABLED");
        assign uart_tx_pin = uart_rx_sync;

        // Optionally ensure your project is not submitted in loopback mode
        // MODULE_FORCE_LOOPBACK_MUST_NOT_BE_ENABLED u_stop ();

    `else
        initial $display("FORCE_LOOPBACK DISABLED");
        assign uart_tx_pin = uo_out[4];
    `endif /* FORCE_LOOPBACK */

    // Optional Debug
    assign led = uo_out;
    // assign led = 8'h00;

endmodule

`default_nettype wire
