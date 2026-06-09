/*
 * Copyright (c) 2026 gojimmypi
 * SPDX-License-Identifier: Apache-2.0
 *
 * See ATTRIBUTION.md for third-party sources and credits.
 *
 * file: test/tb_tt_um_main_jtag.v
 */
`default_nettype none

`timescale 1ns / 1ps

module tb_tt_um_main_jtag;

reg clk;
reg rst_n;
reg ena;

reg [7:0] ui_in;
reg [7:0] uio_in;
wire [7:0] uo_out;
wire [7:0] uio_out;
wire [7:0] uio_oe;

integer errors;

tt_um_main dut (
    .ui_in(ui_in),
    .uo_out(uo_out),
    .uio_in(uio_in),
    .uio_out(uio_out),
    .uio_oe(uio_oe),
    .ena(ena),
    .clk(clk),
    .rst_n(rst_n)
);

initial begin
    clk = 1'b0;
    forever #20 clk = ~clk;  /* 25 MHz */
end

task jtag_clock;
    input tms;
    input tdi;
    begin
        uio_in[0] = tms;  /* TMS */
        uio_in[1] = tdi;  /* TDI */

        /*
         * Leave these delays long relative to clk because jtag_core
         * synchronizes TCK/TMS/TDI into clk.
         */
        #400;
        uio_in[3] = 1'b1; /* TCK high */
        #400;
        uio_in[3] = 1'b0; /* TCK low */
        #400;
    end
endtask

task jtag_reset;
    integer i;
    begin
        for (i = 0; i < 6; i = i + 1) begin
            jtag_clock(1'b1, 1'b0);
        end

        /* Move Test-Logic-Reset -> Run-Test/Idle */
        jtag_clock(1'b0, 1'b0);
    end
endtask

task jtag_idle;
    input integer count;
    integer i;
    begin
        for (i = 0; i < count; i = i + 1) begin
            jtag_clock(1'b0, 1'b0);
        end
    end
endtask

task shift_ir;
    input [3:0] value;
    integer i;
    begin
        /*
         * From Run-Test/Idle:
         * 1 Select-DR
         * 1 Select-IR
         * 0 Capture-IR
         * 0 Shift-IR
         */
        jtag_clock(1'b1, 1'b0);
        jtag_clock(1'b1, 1'b0);
        jtag_clock(1'b0, 1'b0);
        jtag_clock(1'b0, 1'b0);

        for (i = 0; i < 4; i = i + 1) begin
            if (i == 3) begin
                jtag_clock(1'b1, value[i]);
            end else begin
                jtag_clock(1'b0, value[i]);
            end
        end

        /*
         * Exit1-IR -> Update-IR -> Run-Test/Idle
         */
        jtag_clock(1'b1, 1'b0);
        jtag_clock(1'b0, 1'b0);
    end
endtask

task shift_dr_32;
    input [31:0] value;
    output [31:0] captured;
    integer i;
    begin
        captured = 32'h00000000;

        /*
         * From Run-Test/Idle:
         * 1 Select-DR
         * 0 Capture-DR
         * 0 Shift-DR
         */
        jtag_clock(1'b1, 1'b0);
        jtag_clock(1'b0, 1'b0);
        jtag_clock(1'b0, 1'b0);

        for (i = 0; i < 32; i = i + 1) begin
            /*
             * TDO is uio_out[2] in tt_um_main.
             * Sample before the next bit cycle.
             */
            captured[i] = uio_out[2];

            if (i == 31) begin
                jtag_clock(1'b1, value[i]);
            end else begin
                jtag_clock(1'b0, value[i]);
            end
        end

        /*
         * Exit1-DR -> Update-DR -> Run-Test/Idle
         */
        jtag_clock(1'b1, 1'b0);
        jtag_clock(1'b0, 1'b0);
    end
endtask

task expect32;
    input [31:0] got;
    input [31:0] expected;
    begin
        if (got !== expected) begin
            $display("FAIL: got 0x%08X expected 0x%08X", got, expected);
            errors = errors + 1;
        end else begin
            $display("PASS: got 0x%08X", got);
        end
    end
endtask

task expect8;
    input [7:0] got;
    input [7:0] expected;
    begin
        if (got !== expected) begin
            $display("FAIL: got 0x%02X expected 0x%02X", got, expected);
            errors = errors + 1;
        end else begin
            $display("PASS: got 0x%02X", got);
        end
    end
endtask

reg [31:0] data;

initial begin
    $dumpfile("tb_tt_um_main_jtag.vcd");
    $dumpvars(0, tb_tt_um_main_jtag);

    errors = 0;

    rst_n = 1'b0;
    ena = 1'b0;

    /*
     * ui_in[4] = 0 selects JTAG.
     * ui_in[3] = 1 keeps UART RX idle.
     */
    ui_in = 8'h08;

    uio_in = 8'h00;
    uio_in[0] = 1'b1; /* TMS idle high during reset setup */
    uio_in[3] = 1'b0; /* TCK low */

    #1000;

    rst_n = 1'b1;
    ena = 1'b1;

    #1000;

    /******************************************************************************/
    $display("Test 1: tt_um_main JTAG select and UIO direction");
    /******************************************************************************/
    if (uio_oe !== 8'hF4) begin
        $display("FAIL: uio_oe got 0x%02X expected 0xF4", uio_oe);
        errors = errors + 1;
    end else begin
        $display("PASS: uio_oe got 0x%02X", uio_oe);
    end

    /******************************************************************************/
    $display("Test 2: IDCODE through tt_um_main uio pins");
    /******************************************************************************/
    jtag_reset();
    shift_dr_32(32'h00000000, data);
    expect32(data, 32'h54544A31);

    /******************************************************************************/
    $display("Test 3: write R2 through JTAG");
    jtag_reset();

    shift_ir(4'h2);              /* REG_ADDR */
    shift_dr_32(32'h00000002, data);
    jtag_idle(2);

    shift_ir(4'h4);              /* REG_WRITE */
    shift_dr_32(32'h000000A5, data);
    jtag_idle(4);

    #2000;

    expect8(dut.reg_div, 8'hA5);

    /******************************************************************************/
    $display("Test 3A: read R2 through JTAG");
    /******************************************************************************/
    shift_ir(4'h2);              /* REG_ADDR */
    shift_dr_32(32'h00000002, data);
    jtag_idle(4);

`ifdef JTAG_TB_DEBUG
    $display("DEBUG: dut.reg_div       = 0x%02X", dut.reg_div);
    $display("DEBUG: dut.spi_reg_addr  = 0x%01X", dut.spi_reg_addr);
    $display("DEBUG: dut.spi_reg_rdata = 0x%02X", dut.spi_reg_rdata);

    $display("DEBUG: dut.reg_ctrl      = 0x%02X", dut.reg_ctrl);
    $display("DEBUG: dut.reg_src       = 0x%02X", dut.reg_src);
    $display("DEBUG: dut.reg_div       = 0x%02X", dut.reg_div);
    $display("DEBUG: dut.reg_mode      = 0x%02X", dut.reg_mode);
    $display("DEBUG: dut.reg_oscen     = 0x%02X", dut.reg_oscen);
    $display("DEBUG: dut.reg_status    = 0x%02X", dut.reg_status);
    $display("DEBUG: dut.reg_rawlo     = 0x%02X", dut.reg_rawlo);
    $display("DEBUG: dut.reg_rawhi     = 0x%02X", dut.reg_rawhi);

    $display("DEBUG: readback sweep");

    shift_ir(4'h2);
    shift_dr_32(32'h00000000, data);
    jtag_idle(2);
    $display("DEBUG: addr 0 rdata 0x%02X", dut.spi_reg_rdata);

    shift_ir(4'h2);
    shift_dr_32(32'h00000001, data);
    jtag_idle(2);
    $display("DEBUG: addr 1 rdata 0x%02X", dut.spi_reg_rdata);

    shift_ir(4'h2);
    shift_dr_32(32'h00000002, data);
    jtag_idle(2);
    $display("DEBUG: addr 2 rdata 0x%02X", dut.spi_reg_rdata);

    shift_ir(4'h2);
    shift_dr_32(32'h00000003, data);
    jtag_idle(2);
    $display("DEBUG: addr 3 rdata 0x%02X", dut.spi_reg_rdata);

    shift_ir(4'h2);
    shift_dr_32(32'h00000004, data);
    jtag_idle(2);
    $display("DEBUG: addr 4 rdata 0x%02X", dut.spi_reg_rdata);

    /*
     * Restore R2 because the sweep leaves address 4 selected.
     */
    shift_ir(4'h2);              /* REG_ADDR */
    shift_dr_32(32'h00000002, data);
    jtag_idle(4);
`endif

    shift_ir(4'h3);              /* REG_READ */
    jtag_idle(2);
    shift_dr_32(32'h00000000, data);
    jtag_idle(2);

    expect8(data[7:0], 8'hA5);

    /******************************************************************************/
    $display("Test 4: switch to SPI mode disables JTAG TDO path");
    /******************************************************************************/
    ui_in[4] = 1'b1;             /* SPI mode, not JTAG */
    #2000;

    if (uio_out[2] !== 1'b0 && uio_out[2] !== 1'b1) begin
        $display("FAIL: uio_out[2] is unknown in SPI mode");
        errors = errors + 1;
    end else begin
        $display("PASS: uio_out[2] is driven in SPI mode");
    end

    if (errors == 0) begin
        $display("PASS: all tt_um_main JTAG integration tests passed");
    end else begin
        $display("FAIL: %0d errors", errors);
    end

    $finish;
end

endmodule

`default_nettype wire