/*
 * Copyright (c) 2026 gojimmypi
 * SPDX-License-Identifier: Apache-2.0
 *
 * See ATTRIBUTION.md for third-party sources and credits.
 *
 * file: trng_lab_core.v
 *
 * Experimental TRNG lab core.
 *
 * This is intended for education and experimentation.
 * It is not a certified cryptographic random number generator.
 *
 * WARNING: There's a bit of hackery in this file to allow the real RO-based TRNG code 
 * to be included only when explicitly enabled, and only in appropriate build environments.
 * Note the project.v settings for TRNG_USE_RO and TRNG_ALLOW_REAL_RO, and the conditional 
 * code below that checks for these defines. (in particular the `ifdef __pnr__`)
 *
 * There's an additional manual identification of PDK in root-level target_pdk.v included by project.v, 
 * which is used to conditionally instantiate the correct standard cells in the RO code.
 *
 * See GDS_logs.zip\runs\wokwi\06-yosys-synthesis\tt_um_gojimmypi_ttsky_UART_FSM_TRNG_Lab.nl.v
 *   and confirm this exists: module trng_ro_inverter_cell(a, y);
 *   with many instantiated sky130_fd_sc_hd__inv_2 cells inside. 
 * If you see this, the real RO code is included. If you see instead a module trng_ro_inverter_cell 
 * with no internal cells, then the real RO code is not included and the trng_ro module is just a passthrough.
 *
 * ABC: Error: The network is combinational.
 *   This is GOOD for a ring oscillator design.
 *
 * gdslogs/runs/wokwi/58-klayout-streamout/klayout-streamout.log
 *   Should contain the text:
 *   [INFO] All LEF cells have matching GDS cells.
 */
`default_nettype none

`ifdef SIM_JTAG_CORE_TB
    `timescale 1ns / 1ps
`endif

/* this entire file is only for the TRNG lab core, which is an optional alternative to the trng_stub */
`ifdef TRNG_ENABLED

`ifndef LINT_OFF_PINMISSING_POWER_PINS
    `ifdef USE_POWER_PINS
        `define LINT_OFF_PINMISSING_POWER_PINS /* verilator lint_off PINMISSING */
        `define LINT_ON_PINMISSING_POWER_PINS  /* verilator lint_on PINMISSING */
    `else
        `define LINT_OFF_PINMISSING_POWER_PINS /* */
        `define LINT_ON_PINMISSING_POWER_PINS  /* */
    `endif
`endif

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

`ifdef TRNG_CONDITIONED_STREAM
    `ifdef TRNG_CONDITIONED_STREAM_64_XOR
    output wire [7:0] reg_cond0,
    output wire [7:0] reg_cond1,
    output wire [7:0] reg_cond2,
    output wire [7:0] reg_cond3,
    output wire [7:0] reg_cond4,
    output wire [7:0] reg_cond5,
    output wire [7:0] reg_cond6,
    output wire [7:0] reg_cond7,
    `else
    output wire [7:0] reg_condlo,
    output wire [7:0] reg_condhi,
    `endif
`endif

    output wire       trng_bit
);

    localparam [1:0] SRC_LFSR = 2'b00;
    localparam [1:0] SRC_RO0  = 2'b01;
    localparam [1:0] SRC_ROX  = 2'b10;
    localparam [1:0] SRC_MIX  = 2'b11;

    reg  [15:0] sample_ctr;
    reg  [15:0] lfsr;
    reg  [15:0] sample_shift;
`ifdef TRNG_CONDITIONED_STREAM
    `ifdef TRNG_CONDITIONED_STREAM_64_XOR
    reg  [63:0] stream_mix;
    `else
    reg  [31:0] stream_mix;
    `endif
`endif

    reg         ro0_sample_meta;
    reg         ro0_sample_sync;
    reg         rox_sample_meta;
    reg         rox_sample_sync;
    reg         selected_bit;

    reg         trng_step_d;
    reg         sample_tick_q;
    reg         do_sample_q;

    wire        trng_step;
    wire        trng_step_pulse;

    wire        trng_enable;
    wire        sample_tick;
    wire [1:0]  source_select;

    wire [7:0]  ro_raw;
    wire        ro_xor;
    wire        lfsr_next_bit;
`ifdef TRNG_CONDITIONED_STREAM
    wire        stream_feedback;
    `ifdef TRNG_CONDITIONED_STREAM_64_XOR
    wire [63:0] stream_scrambled;
    `endif
`endif

    wire        unused_reg_ctrl;
    wire        unused_reg_src;
    wire        unused_reg_mode;
    wire        unused_sample_shift;

    wire        trng_reset;

    assign trng_reset = reg_ctrl[2];

    /* reg_ctrl[1], written by V1/V0, is a deterministic single-step request. */
    assign trng_step = reg_ctrl[1];
    assign trng_step_pulse = trng_step && !trng_step_d;

    assign trng_enable = reg_ctrl[0];
    assign source_select = reg_src[1:0];

    assign sample_tick = sample_ctr >= {8'h00, reg_div};

    assign lfsr_next_bit = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10];

    assign ro_xor = ro_raw[0] ^ ro_raw[1] ^ ro_raw[2] ^ ro_raw[3] ^
                    ro_raw[4] ^ ro_raw[5] ^ ro_raw[6] ^ ro_raw[7];

    assign trng_bit = sample_shift[0];

`ifdef TRNG_CONDITIONED_STREAM
`ifdef TRNG_CONDITIONED_STREAM_64_XOR
    assign stream_feedback =
        stream_mix[63] ^
        stream_mix[62] ^
        stream_mix[60] ^
        stream_mix[59] ^
        selected_bit   ^
        ro0_sample_sync ^
        rox_sample_sync ^
        lfsr[0]        ^
        lfsr[7]        ^
        lfsr[15]       ^
        sample_shift[3] ^
        sample_shift[11];

    assign stream_scrambled =
        stream_mix ^
        {7'h00, stream_mix[63:7]} ^
        {17'h00000, stream_mix[63:17]} ^
        {31'h00000000, stream_mix[63:31]};

    assign reg_cond0 = stream_scrambled[7:0]   ^ stream_scrambled[39:32] ^ stream_scrambled[63:56];
    assign reg_cond1 = stream_scrambled[15:8]  ^ stream_scrambled[47:40] ^ stream_scrambled[31:24];
    assign reg_cond2 = stream_scrambled[23:16] ^ stream_scrambled[55:48] ^ stream_scrambled[7:0];
    assign reg_cond3 = stream_scrambled[31:24] ^ stream_scrambled[63:56] ^ stream_scrambled[15:8];
    assign reg_cond4 = stream_scrambled[39:32] ^ stream_scrambled[7:0]   ^ stream_scrambled[23:16];
    assign reg_cond5 = stream_scrambled[47:40] ^ stream_scrambled[15:8]  ^ stream_scrambled[31:24];
    assign reg_cond6 = stream_scrambled[55:48] ^ stream_scrambled[23:16] ^ stream_scrambled[39:32];
    assign reg_cond7 = stream_scrambled[63:56] ^ stream_scrambled[31:24] ^ stream_scrambled[47:40];
`else
    assign stream_feedback =
        stream_mix[31] ^
        stream_mix[21] ^
        stream_mix[1]  ^
        stream_mix[0]  ^
        selected_bit   ^
        lfsr[0]        ^
        lfsr[7]        ^
        lfsr[15];

    assign reg_condlo = stream_mix[7:0]  ^ stream_mix[31:24];
    assign reg_condhi = stream_mix[15:8] ^ stream_mix[23:16];
`endif /* !TRNG_CONDITIONED_STREAM_64_XOR */
`endif /* TRNG_CONDITIONED_STREAM */

    assign unused_reg_ctrl = &reg_ctrl[7:3];
    assign unused_reg_src  = &reg_src[7:2];
    assign unused_reg_mode = &reg_mode[7:3];
    assign unused_sample_shift = sample_shift[15];

/*
 * The real RO path instantiates SKY130 standard cells.
 * Keep it disabled for normal simulation and FPGA builds.
 * Enable it only for an explicit ASIC RO experiment by defining both:
 * TRNG_USE_RO and TRNG_ALLOW_REAL_RO.
 */
`ifdef TRNG_USE_RO
    `ifdef FPGA
        /* TRNG_USE_RO is not supported for FPGA builds. Please remove TRNG_USE_RO definition. */
        FPGA_TRNG_USE_RO_NOT_SUPPORTED u_stop ();
    `endif
    `ifdef SYNTH
        /* TRNG_USE_RO is not supported for FPGA builds. Please remove TRNG_USE_RO definition. */
        SYNTH_TRNG_USE_RO_NOT_SUPPORTED u_stop ();
    `endif

    `ifdef TRNG_ALLOW_REAL_RO
        /* TRNG_LAB_USE_REAL_RO is used internally to conditionally include the real RO code. 
         * Do not define externally as there are multiple build paths during testing (e.g. FPGA) */
        `define TRNG_LAB_USE_REAL_RO
    `endif
`endif

`ifdef TRNG_LAB_USE_REAL_RO
    /* Real ring oscillator path. Requires explicit TRNG_ALLOW_REAL_RO. */
    trng_ro #(.STAGES(3))  u_ro0 (.enable(reg_oscen[0]), .ro_out(ro_raw[0]));
    trng_ro #(.STAGES(5))  u_ro1 (.enable(reg_oscen[1]), .ro_out(ro_raw[1]));
    trng_ro #(.STAGES(7))  u_ro2 (.enable(reg_oscen[2]), .ro_out(ro_raw[2]));
    trng_ro #(.STAGES(9))  u_ro3 (.enable(reg_oscen[3]), .ro_out(ro_raw[3]));
    trng_ro #(.STAGES(11)) u_ro4 (.enable(reg_oscen[4]), .ro_out(ro_raw[4]));
    trng_ro #(.STAGES(13)) u_ro5 (.enable(reg_oscen[5]), .ro_out(ro_raw[5]));
    trng_ro #(.STAGES(15)) u_ro6 (.enable(reg_oscen[6]), .ro_out(ro_raw[6]));
    trng_ro #(.STAGES(17)) u_ro7 (.enable(reg_oscen[7]), .ro_out(ro_raw[7]));

`else
    /* Typical simulation or FPGA path. The "RO" bits are just taps from the LFSR. */

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
        if (!rst_n || trng_reset) begin
            trng_step_d     <= 1'b0;
            sample_tick_q   <= 1'b0;
            do_sample_q     <= 1'b0;

            sample_ctr      <= 16'h0000;
            lfsr            <= 16'h1ACE;
            sample_shift    <= 16'h0000;
`ifdef TRNG_CONDITIONED_STREAM
    `ifdef TRNG_CONDITIONED_STREAM_64_XOR
            /* Nonzero fixed conditioner seed. This is not a secret key and does not
             * provide entropy. It only prevents the conditioner from starting at zero. 
             * ASCII "gojimmy!" makes the value traceable and intentional. */
            stream_mix <= 64'h676F_6A69_6D6D_7921; // "gojimmy!"
    `else
            stream_mix      <= 32'hA5C3_1F2D;
    `endif
`endif
            ro0_sample_meta <= 1'b0;
            ro0_sample_sync <= 1'b0;
            rox_sample_meta <= 1'b0;
            rox_sample_sync <= 1'b0;
            reg_status      <= 8'h00;
            reg_rawlo       <= 8'h00;
            reg_rawhi       <= 8'h00;
        end else begin
            trng_step_d     <= trng_step;
            sample_tick_q   <= sample_tick;
            do_sample_q     <= (trng_enable && sample_tick) || trng_step_pulse;

            ro0_sample_meta <= ro_raw[0];
            ro0_sample_sync <= ro0_sample_meta;

            rox_sample_meta <= ro_xor;
            rox_sample_sync <= rox_sample_meta;

            reg_status[0]   <= trng_enable;
            reg_status[1]   <= sample_tick_q;
            reg_status[2]   <= |reg_oscen;
            reg_status[4:3] <= source_select;
            reg_status[7:5] <= reg_mode[2:0];

            if (do_sample_q) begin
                sample_ctr   <= 16'h0000;
                lfsr         <= {lfsr[14:0], lfsr_next_bit};
                sample_shift <= {sample_shift[14:0], selected_bit};
                reg_rawlo    <= {sample_shift[6:0], selected_bit};
                reg_rawhi    <= sample_shift[14:7];
`ifdef TRNG_CONDITIONED_STREAM
`ifdef TRNG_CONDITIONED_STREAM_64_XOR
                stream_mix   <= {
                    stream_mix[62:0],
                    stream_feedback
                } ^ {
                    reg_rawhi,
                    reg_rawlo,
                    sample_shift[15:8],
                    sample_shift[7:0],
                    lfsr[15:8],
                    lfsr[7:0],
                    ro_raw,
                    {7'b0000000, selected_bit}
                };
`else
                stream_mix   <= {
                    stream_mix[30:0],
                    stream_feedback
                } ^ {
                    reg_rawhi,
                    reg_rawlo,
                    sample_shift[15:8],
                    sample_shift[7:0]
                };
`endif /* !TRNG_CONDITIONED_STREAM_64_XOR */
`endif /* TRNG_CONDITIONED_STREAM */

            end else if (trng_enable) begin
                sample_ctr <= sample_ctr + 16'h0001;

            end else begin
                sample_ctr <= 16'h0000;
            end
        end
    end

endmodule /* trng_lab_core */

`ifdef TRNG_LAB_USE_REAL_RO

module trng_ro_inverter_cell
(
    input  wire a,
    output wire y
);

    `LINT_OFF_PINMISSING_POWER_PINS

    /* See target.pdk.v included at the top-level project.v for the PDK selection. 
     * The cells instantiated here must match the selected PDK. */ 
    `ifdef PDK_TARGET_SKY130
        /* See https://sky130-unofficial.readthedocs.io/en/latest/contents/libraries/sky130_fd_sc_hd/cells/inv/README.html */
        (* keep_hierarchy *) sky130_fd_sc_hd__inv_2 u_inv
        (
            .A(a),
            .Y(y)
        );
    `elsif PDK_TARGET_GF180
        /* not a valid GF detector: https://github.com/gojimmypi/ttgf-UART-FSM-TRNG-Lab/actions/runs/26855846226/job/79198383591 */
        // `ifdef gf180mcu_fd_sc_mcu7t5v0
        //    /* if a macro, we found it, success! for GF180 detection*/
        //    PROJECT_FOUND_PDK u_stop ();
        //`endif
        /* See https://github.com/google/globalfoundries-pdk-libs-gf180mcu_fd_sc_mcu7t5v0/blob/main/cells/inv/gf180mcu_fd_sc_mcu7t5v0__inv_1.functional.v */
        (* keep_hierarchy *) gf180mcu_fd_sc_mcu7t5v0__inv_1 u_inv
        (
            .I(a),
            .ZN(y)
        );
    `else
        PROJECT_ASIC_SKY130_OR_GF180_ONLY u_stop (); /* Only SKY130 and GF180 supported at this time */
    `endif

    `LINT_ON_PINMISSING_POWER_PINS

endmodule /* trng_ro_inverter_cell */

module trng_ro
#(
    parameter integer STAGES = 3
)
(
    input  wire enable,
    output wire ro_out
);

    wire [STAGES-1:0] inv_in;
    wire [STAGES-1:0] inv_out;

    assign inv_in[STAGES-1:1] = inv_out[STAGES-2:0];
    assign inv_in[0] = inv_out[STAGES-1] & enable;

    assign ro_out = inv_in[0];

    (* keep_hierarchy *) trng_ro_inverter_cell inv_array [STAGES-1:0]
    (
        .a(inv_in),
        .y(inv_out)
    );

endmodule /* trng_ro */

`endif /* TRNG_LAB_USE_REAL_RO */

`ifdef TRNG_LAB_USE_REAL_RO
    `undef TRNG_LAB_USE_REAL_RO
`endif

`ifdef LINT_OFF_PINMISSING_POWER_PINS
    `undef LINT_OFF_PINMISSING_POWER_PINS
`endif

`ifdef LINT_ON_PINMISSING_POWER_PINS
    `undef LINT_ON_PINMISSING_POWER_PINS
`endif

`endif /* TRNG_ENABLED */

`default_nettype wire
