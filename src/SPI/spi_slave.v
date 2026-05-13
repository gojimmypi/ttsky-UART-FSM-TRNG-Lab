/*
 * Copyright (c) 2026 gojimmypi
 * SPDX-License-Identifier: Apache-2.0
 *
 * file: tt_spi_slave.v
 *
 * Simple SPI slave helper for Tiny Tapeout experiments.
 *
 * Current implementation:
 * - SPI mode 0 (CPOL=0, CPHA=0)
 * - MSB first
 * - transmit-only test path
 * - fixed transmit byte
 */

`default_nettype none

module tt_spi_slave
(
    input  wire       clk,
    input  wire       rst_n,

    input  wire       spi_sck,
    input  wire       spi_cs_n,
    input  wire       spi_mosi,

    output reg        spi_miso
);

    /* Reminder the Tx byte comes from the ESP32; see main.c */
`ifdef SPI_TEST_BYTE
    /* see project.v for how to set this value; default is 0x42 */
    localparam [7:0] SPI_TEST_BYTE_VAL = `SPI_TEST_BYTE;
`else
    localparam [7:0] SPI_TEST_BYTE_VAL = 8'h42;
`endif

    localparam SPI_IDLE_MISO = 1'b1;

    reg [2:0] spi_sck_sync;
    reg [2:0] spi_cs_sync;
    reg [7:0] spi_tx_shift;

    wire spi_sck_fall;
    wire spi_cs_start;
    wire spi_cs_active;

    /* Keep currently-unused MOSI referenced */
    wire unused_ok;
    assign unused_ok = &{1'b0, spi_mosi};

    assign spi_sck_fall  = spi_sck_sync[2:1] == 2'b10;
    assign spi_cs_start  = spi_cs_sync[2:1] == 2'b10;
    assign spi_cs_active = !spi_cs_sync[2];

    always @(posedge clk) begin
        if (!rst_n) begin
            spi_sck_sync <= 3'b000;
            spi_cs_sync  <= 3'b111;

`ifdef SPI_TEST_FIXED
            spi_tx_shift <= SPI_TEST_BYTE_VAL;
            spi_miso     <= SPI_IDLE_MISO;
`else
            spi_tx_shift <= 8'h00;
            spi_miso     <= SPI_IDLE_MISO;
`endif

        end else begin
            spi_sck_sync <= {spi_sck_sync[1:0], spi_sck};
            spi_cs_sync  <= {spi_cs_sync[1:0], spi_cs_n};

            /* SPI slave, mode 0 (CPOL=0, CPHA=0), MSB-first */
            /*
             * CS_N falls  -> preload first MISO bit
             * SCK rises   -> ESP32 samples valid bit
             * SCK falls   -> TT prepares next bit
             */

            if (spi_cs_start) begin
`ifdef SPI_TEST_FIXED
                /*
                 * Preload shift register so bit6 is ready after
                 * the first falling edge.
                 */
                spi_tx_shift <= {SPI_TEST_BYTE_VAL[6:0], 1'b0};

                /*
                 * Present bit7 immediately so the master samples
                 * valid data on the first rising edge.
                 */
                spi_miso <= SPI_TEST_BYTE_VAL[7];
`endif

            end else if (spi_cs_active && spi_sck_fall) begin
                /* Present next bit */
                spi_miso <= spi_tx_shift[7];

                /* Shift for following bit */
                spi_tx_shift <= {spi_tx_shift[6:0], 1'b0};
            end
        end
    end

endmodule

`default_nettype wire
