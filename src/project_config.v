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

/* We only want to include this file once, but it may be referenced BOTH by:
 *   - project.v
 *   - top_ulxs.v
 *   - other wrappers
 */
`ifndef PROJECT_CONFIG_V
    `define PROJECT_CONFIG_V

    /* There's about a 5% (~ 100 cells) increase in the number of cells when using long strings.
     * Currently only the version string is implemented. */
    `define USE_LONG_STRINGS
    `define VERSION_STRING_LEN 22 /* 123456789012345678901234 */   
    `define VERSION_STRING          "Version 0.1.7 6/7/2026"   

    /* Optionally Perform a blinky test on led[0] to confirm we have a working clock */
    // `define ULX3S_CLOCK_TEST

    /* The 50 MHz clock on gn12 is only available when using HDMI on the ULX3S */
    // `define ULX3S_USE_GN12_50MHZ

    `ifdef ULX3S_USE_GN12_50MHZ
        `define PROJECT_CLOCK_HZ 32'd50000000
    `endif

    `ifndef PROJECT_CLOCK_HZ
       `define PROJECT_CLOCK_HZ 32'd25000000
    `endif

    `ifndef PROJECT_UART_BAUD
        `define PROJECT_UART_BAUD 32'd115_200
    `endif

`endif /* PROJECT_CONFIG_V */

`default_nettype wire
