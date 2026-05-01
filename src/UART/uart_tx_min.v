/*
 * Copyright (c) 2026 gojimmypi
 * SPDX-License-Identifier: Apache-2.0
 *
 * See ATTRIBUTION.md for third-party sources and credits.
 * 
 * The minimal UART RX and TX modules in this repository are original implementations
 * inspired by common FPGA UART examples, including:
 *
 *  https://nandland.com/uart-serial-port-module/
 *
 * file: uart_tx_min.v
 *
 * Minimal UART transmitter.
 *
 * Purpose:
 * - Sends one 8-bit byte over a UART TX line in 8N1 format.
 * - Asserts busy while a transfer is in progress.
 *
 * UART format:
 * - idle line high
 * - 1 start bit low
 * - 8 data bits, LSB first
 * - 1 stop bit high
 *
 * Handshake:
 * - start is sampled in ST_IDLE.
 * - data_in is captured only when a new transfer begins.
 * - busy stays high from start-bit launch until the stop bit completes.
 */
`default_nettype none

module uart_tx_min
#(
    parameter [31:0] CLOCK_HZ  = 32'd25000000,
    parameter [31:0] UART_BAUD = 32'd115200
)
(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] data_in,
    input  wire       start,
    output reg        tx,
    output reg        busy
);
    localparam integer CLKS_PER_BIT = CLOCK_HZ / UART_BAUD;
    localparam integer CLKS_PER_BIT_M1  = CLKS_PER_BIT - 1;
 // localparam [15:0] CLKS_PER_HALF_M1 = (CLKS_PER_BIT >> 1) - 16'd1;
 // localparam [15:0] CLKS_PER_BIT_16    = CLKS_PER_BIT[15:0];
    localparam [15:0] CLKS_PER_BIT_M1_16 = CLKS_PER_BIT_M1[15:0];
 // localparam [15:0] CLKS_PER_HALF_M1_16 = CLKS_PER_HALF_M1[15:0];

    localparam [1:0] ST_IDLE  = 2'd0;
    localparam [1:0] ST_START = 2'd1;
    localparam [1:0] ST_DATA  = 2'd2;
    localparam [1:0] ST_STOP  = 2'd3;

    reg [1:0]  state;

    /*
     * shift_reg holds remaining bits to transmit.
     * The LSB is always the next data bit sent.
     */
    reg [7:0]  shift_reg;
    reg [3:0]  bit_index;
    reg [15:0] clk_count;

    always @(posedge clk) begin
        if (!rst_n) begin
            state     <= ST_IDLE;
            tx        <= 1'b1;
            busy      <= 1'b0;
            shift_reg <= 8'h00;
            bit_index <= 4'd0;
            clk_count <= 16'd0;
        end else begin
            case (state)
                ST_IDLE: begin
                    /* Line is idle-high when not transmitting. */
                    tx        <= 1'b1;
                    busy      <= 1'b0;
                    clk_count <= 16'd0;
                    bit_index <= 4'd0;

                    if (start) begin
                        /*
                         * Capture the byte and immediately drive the start bit.
                         * The first data bit will be launched after one full bit
                         * period in ST_START.
                         */
                        shift_reg <= data_in;
                        busy      <= 1'b1;
                        tx        <= 1'b0;
                        state     <= ST_START;
                    end
                end

                ST_START: begin
                    busy <= 1'b1;

                    if (clk_count == CLKS_PER_BIT_M1_16) begin
                        clk_count <= 16'd0;

                        /* Put the first payload bit on the line. */
                        tx        <= shift_reg[0];
                        shift_reg <= {1'b0, shift_reg[7:1]};
                        bit_index <= 4'd1;
                        state     <= ST_DATA;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                ST_DATA: begin
                    busy <= 1'b1;

                    if (clk_count == CLKS_PER_BIT_M1_16) begin
                        clk_count <= 16'd0;

                        if (bit_index < 4'd8) begin
                            /* Continue shifting out remaining data bits. */
                            tx        <= shift_reg[0];
                            shift_reg <= {1'b0, shift_reg[7:1]};
                            bit_index <= bit_index + 1'b1;
                        end else begin
                            /* After the eighth bit, drive the stop bit high. */
                            tx    <= 1'b1;
                            state <= ST_STOP;
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                ST_STOP: begin
                    busy <= 1'b1;

                    if (clk_count == CLKS_PER_BIT_M1_16) begin
                        clk_count <= 16'd0;
                        state     <= ST_IDLE;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule

`default_nettype wire
