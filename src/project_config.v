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

    `ifdef USE_LONG_STRINGS
        `define VERSION_STRING_LEN 24 /* 123456789012345678901234 */   
        `define VERSION_STRING          "Version 0.1.7b 6/10/2026"   
    `else
        /* no long strings */
    `endif

    /* For TT ASIC, command are only upper case, with both of the following
     * case insensitive options NOT ENABLED due to decreases slew and setup. */

    /* Add some logic to make UART interactive commands case insensitive */
    // `define CASE_INSENSITIVE

    /* Add additional alternative compares for case insensitive command chars */
    // `define CASE_INSENSITIVE_ALT


    /* Optionally Perform a blinky test on led[0] to confirm we have a working clock */
    // `define ULX3S_CLOCK_TEST

    /* The 50 MHz clock on gn12 is only available when using HDMI on the ULX3S */
    // `define ULX3S_USE_GN12_50MHZ

    `ifdef ULX3S_USE_GN12_50MHZ
        `define PROJECT_CLOCK_HZ 32'd50_000_000
    `endif

    `ifndef PROJECT_CLOCK_HZ
       `define PROJECT_CLOCK_HZ 32'd25_000_000
    `endif

    `ifndef PROJECT_UART_BAUD
        `define PROJECT_UART_BAUD 32'd115_200
    `endif

    /* Some project features, typically only changed during development and debugging: */

    // `define ANALOG_ENABLED
    `define UART_ENABLED
    `define SPI_ENABLED
    `define SPI_REG_ACCESS
    `define TRNG_ENABLED
    `define JTAG_ENABLED

    /* Note that with all UART_ENABLED, SPI_ENABLED, SPI_REG_ACCESS, TRNG_ENABLED, JTAG_ENABLED
     * also enabling PIN_DIAG pushes design over 80% of 1x2 tiles. GDS aborted after 90 minute run. */
    `ifdef ULX3S
        // `define PIN_DIAG
    
    `elsif IS_MY_IVERILOG_SIMULATION 
        /* This is used by the [project]/test/my_test.sh simulation test script */
        // `define PIN_DIAG

    `else
        /* The PIN diag not implemented in 1x2 tile setting for TT at this time. */
    `endif

    /* SPI_TEST_BYTE is only used when SPI_TEST_FIXED is enabled. */
    // `define SPI_TEST_BYTE 8'hD2

    /* Pick zero or one of these SPI tests. Leave both disabled for register access. */
    // `define SPI_TEST_FIXED
    // `define SPI_TEST_ECHO


    /* Some final config sanity checks */
    `ifdef CASE_INSENSITIVE
        `ifdef CASE_INSENSITIVE_ALT
            PROJECT_MUST_PICK_ZERO_OR_ONE_CASE_INSENSITIVE_ALT u_stop (); /* Cannot use both CASE_INSENSITIVE and CASE_INSENSITIVE_ALT */
        `endif
    `endif

    `ifdef CASE_INSENSITIVE_ALT
        `ifdef CASE_INSENSITIVE
            PROJECT_MUST_PICK_ZERO_OR_ONE_CASE_INSENSITIVE u_stop ();  /* Cannot use both CASE_INSENSITIVE and CASE_INSENSITIVE_ALT */
        `endif
    `endif

`endif /* PROJECT_CONFIG_V */

`default_nettype wire
