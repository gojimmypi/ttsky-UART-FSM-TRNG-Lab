/*
 * Copyright (c) 2026 gojimmypi
 * SPDX-License-Identifier: Apache-2.0
 *
 * See ATTRIBUTION.md for third-party sources and credits.
 *
 * file: trng_stub.v
 ^
 * Deterministic stand-in for a future real TRNG.
 *
 * Purpose:
 * - Lets the UART command path, register map, and readback logic be tested
 *   before a true entropy source is integrated.
 * - Produces changing data values so read commands have something useful to
 *   return on ULX3S and in Tiny Tapeout simulations.
 *
 * Important limitation:
 * - This is not true random data.
 * - It is an LFSR-based pseudo-random source controlled by a simple divider.
 */
`default_nettype none

module trng_stub
(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] reg_ctrl,
    input  wire [7:0] reg_src,
    input  wire [7:0] reg_div,
    input  wire [7:0] reg_mode,
    input  wire       reg_oscen, /* oscillator enable */
    output reg  [7:0] reg_status,
    output reg  [7:0] reg_rawlo,
    output reg  [7:0] reg_rawhi,
    output wire       trng_bit
);

    /*
     * sample_ctr acts as a programmable rate divider.
     * lfsr holds the current pseudo-random state.
     */
    reg [15:0] sample_ctr;
    reg [15:0] lfsr;
    wire trng_enable;

    /* These are 8-bit UART-visible registers. The stub currently uses only
     * selected low bits. Upper bits are reserved for future TRNG controls.
     */
    wire _unused_reg_ctrl  = &reg_ctrl[7:3];
    wire _unused_reg_src   = &reg_src[7:2];
    wire _unused_reg_mode  = &reg_mode[7:3];

    /* Enable bit comes from reg_ctrl[0], matching the ASCII register front-end. */
    assign trng_enable = reg_ctrl[0];

    /* Export the current LFSR LSB as a single-bit entropy-like signal. */
    assign trng_bit = lfsr[0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_ctr <= 16'h0000;
            lfsr       <= 16'h1ACE;
            reg_status <= 8'h00;
            reg_rawlo  <= 8'h00;
            reg_rawhi  <= 8'h00;
        end else begin
            /*
             * Publish selected configuration bits in reg_status so software can
             * verify that writes were accepted and can inspect current mode.
             */
            reg_status[0]   <= trng_enable;
            reg_status[1]   <= reg_ctrl[1];
            reg_status[2]   <= reg_ctrl[2];
            reg_status[4:3] <= reg_src[1:0];
            reg_status[7:5] <= reg_mode[2:0];

            if (trng_enable) begin
                /*
                 * Wait until sample_ctr reaches the programmed divider value.
                 * At that point, advance the LFSR and publish a new 16-bit word.
                 */
                if (sample_ctr >= {8'h00, reg_div}) begin
                    sample_ctr <= 16'h0000;

                    /*
                     * LFSR feedback uses fixed taps plus two control inputs.
                     * reg_oscen[0] and reg_src[0] are mixed in so command writes
                     * visibly influence the stub output during bring-up.
                     */
                    lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10] ^ reg_oscen ^ reg_src[0]};
                    reg_rawlo <= lfsr[7:0];
                    reg_rawhi <= lfsr[15:8];
                end else begin
                    sample_ctr <= sample_ctr + 1'b1;
                end
            end
        end
    end

endmodule

`default_nettype wire
