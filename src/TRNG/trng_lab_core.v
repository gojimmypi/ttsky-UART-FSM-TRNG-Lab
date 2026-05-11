/*
 * Copyright (c) 2026 gojimmypi
 * SPDX-License-Identifier: Apache-2.0
 *
 * file: trng_lab_core.v
 *
 * Experimental TRNG lab core.
 *
 * This is intended for education and experimentation.
 * It is not a certified cryptographic random number generator.
 */
`default_nettype none

/* this entire file is only for the TRNG lab core, which is an optional alternative to the trng_stub */
`ifdef TRNG_ENABLED

module trng_lab_core
(
    input  wire       clk,
    input  wire       rst_n,

    input  wire [7:0] reg_ctrl,
    input  wire [7:0] reg_src,
    input  wire [7:0] reg_div,
    input  wire [7:0] reg_mode,
    input  wire [7:0] reg_oscen,

    output reg  [7:0] reg_status,
    output reg  [7:0] reg_rawlo,
    output reg  [7:0] reg_rawhi,
    output wire       trng_bit
);

    localparam [1:0] SRC_LFSR = 2'b00;
    localparam [1:0] SRC_RO0  = 2'b01;
    localparam [1:0] SRC_ROX  = 2'b10;
    localparam [1:0] SRC_MIX  = 2'b11;

    reg  [15:0] sample_ctr;
    reg  [15:0] lfsr;
    reg  [15:0] sample_shift;

    reg         ro0_sample_meta;
    reg         ro0_sample_sync;
    reg         rox_sample_meta;
    reg         rox_sample_sync;
    reg         selected_bit;

    wire        trng_enable;
    wire        sample_tick;
    wire [1:0]  source_select;

    wire [7:0]  ro_raw;
    wire        ro_xor;
    wire        lfsr_next_bit;

    wire        unused_reg_ctrl;
    wire        unused_reg_src;
    wire        unused_reg_mode;

    assign trng_enable = reg_ctrl[0];
    assign source_select = reg_src[1:0];

    assign sample_tick = sample_ctr >= {8'h00, reg_div};

    assign lfsr_next_bit = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10];

    assign ro_xor = ro_raw[0] ^ ro_raw[1] ^ ro_raw[2] ^ ro_raw[3] ^
                    ro_raw[4] ^ ro_raw[5] ^ ro_raw[6] ^ ro_raw[7];

    assign trng_bit = sample_shift[0];

    assign unused_reg_ctrl = &reg_ctrl[7:3];
    assign unused_reg_src  = &reg_src[7:2];
    assign unused_reg_mode = &reg_mode[7:3];

`ifdef TRNG_USE_RO
    /*  For FPGA or simulation, do not define TRNG_USE_RO */
    /*  For ASIC, define TRNG_USE_RO to instantiate actual ring oscillators. */
    trng_ro #(.STAGES(3))  u_ro0 (.enable(reg_oscen[0]), .ro_out(ro_raw[0]));
    trng_ro #(.STAGES(5))  u_ro1 (.enable(reg_oscen[1]), .ro_out(ro_raw[1]));
    trng_ro #(.STAGES(7))  u_ro2 (.enable(reg_oscen[2]), .ro_out(ro_raw[2]));
    trng_ro #(.STAGES(9))  u_ro3 (.enable(reg_oscen[3]), .ro_out(ro_raw[3]));
    trng_ro #(.STAGES(11)) u_ro4 (.enable(reg_oscen[4]), .ro_out(ro_raw[4]));
    trng_ro #(.STAGES(13)) u_ro5 (.enable(reg_oscen[5]), .ro_out(ro_raw[5]));
    trng_ro #(.STAGES(15)) u_ro6 (.enable(reg_oscen[6]), .ro_out(ro_raw[6]));
    trng_ro #(.STAGES(17)) u_ro7 (.enable(reg_oscen[7]), .ro_out(ro_raw[7]));

`else

    assign ro_raw[0] = lfsr[0];
    assign ro_raw[1] = lfsr[3];
    assign ro_raw[2] = lfsr[5];
    assign ro_raw[3] = lfsr[7];
    assign ro_raw[4] = lfsr[9];
    assign ro_raw[5] = lfsr[11];
    assign ro_raw[6] = lfsr[13];
    assign ro_raw[7] = lfsr[15];

`endif

    always @(*) begin
        case (source_select)
            SRC_LFSR: begin
                selected_bit = lfsr[0];
            end

            SRC_RO0: begin
                selected_bit = ro0_sample_sync;
            end

            SRC_ROX: begin
                selected_bit = rox_sample_sync;
            end

            SRC_MIX: begin
                selected_bit = rox_sample_sync ^ lfsr[0] ^ lfsr[5] ^ sample_shift[3];
            end

            default: begin
                selected_bit = lfsr[0];
            end
        endcase
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            sample_ctr      <= 16'h0000;
            lfsr            <= 16'h1ACE;
            sample_shift    <= 16'h0000;
            ro0_sample_meta <= 1'b0;
            ro0_sample_sync <= 1'b0;
            rox_sample_meta <= 1'b0;
            rox_sample_sync <= 1'b0;
            reg_status      <= 8'h00;
            reg_rawlo       <= 8'h00;
            reg_rawhi       <= 8'h00;
        end else begin
            ro0_sample_meta <= ro_raw[0];
            ro0_sample_sync <= ro0_sample_meta;

            rox_sample_meta <= ro_xor;
            rox_sample_sync <= rox_sample_meta;

            reg_status[0]   <= trng_enable;
            reg_status[1]   <= sample_tick;
            reg_status[2]   <= |reg_oscen;
            reg_status[4:3] <= source_select;
            reg_status[7:5] <= reg_mode[2:0];

            if (trng_enable) begin
                if (sample_tick) begin
                    sample_ctr   <= 16'h0000;
                    lfsr         <= {lfsr[14:0], lfsr_next_bit};
                    sample_shift <= {sample_shift[14:0], selected_bit};
                    reg_rawlo    <= sample_shift[7:0];
                    reg_rawhi    <= sample_shift[15:8];
                end else begin
                    sample_ctr <= sample_ctr + 16'h0001;
                end
            end else begin
                sample_ctr <= 16'h0000;
            end
        end
    end

endmodule

module trng_ro
#(
    parameter integer STAGES = 3
)
(
    input  wire enable,
    output wire ro_out
);

    (* keep *) wire [STAGES:0] ring;

    assign ring[0] = enable ? ~ring[STAGES] : 1'b0;

    genvar i;

    generate
        for (i = 0; i < STAGES; i = i + 1) begin : gen_ro_stage
            assign ring[i + 1] = ~ring[i];
        end
    endgenerate

    assign ro_out = ring[STAGES];

endmodule /* trng_ro */

`endif /* TRNG_ENABLED */

`default_nettype wire
