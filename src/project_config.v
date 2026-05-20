/*
 * Copyright (c) 2026 gojimmypi
 * SPDX-License-Identifier: Apache-2.0
 *
 * See ATTRIBUTION.md for third-party sources and credits.
 *
 * file: project_config.v
 *
 * Project-wide configuration settings for the Tiny Tapeout project
 */
`default_nettype none

`ifndef PROJECT_CONFIG_V

    // `define ULX3S_CLOCK_TEST

    // `define ULX3S_USE_GN12_50MHZ


    `define PROJECT_CONFIG_V

    `ifdef ULX3S_USE_GN12_50MHZ
        `define PROJECT_CLOCK_HZ 50000000
    `endif

    `ifndef PROJECT_CLOCK_HZ
       `define PROJECT_CLOCK_HZ 25000000
    `endif

    `ifndef PROJECT_UART_BAUD
        `define PROJECT_UART_BAUD 115200
    `endif


    localparam [31:0] PROJECT_CLOCK_HZ_VALUE  = 32'd`PROJECT_CLOCK_HZ;
    localparam [31:0] PROJECT_UART_BAUD_VALUE = 32'd`PROJECT_UART_BAUD;

`endif /* PROJECT_CONFIG_V */

`default_nettype wire
