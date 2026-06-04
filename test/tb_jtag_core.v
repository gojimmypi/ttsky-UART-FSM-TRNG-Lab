/*
 * Copyright (c) 2026 gojimmypi
 * SPDX-License-Identifier: Apache-2.0
 *
 * See ATTRIBUTION.md for third-party sources and credits.
 *
 * file: test/tb_jtag_core.v
 */
`default_nettype none

`timescale 1ns / 1ps

module tb_jtag_core;

reg clk;
reg rst_n;
reg ena;

reg tck_i;
reg tms_i;
reg tdi_i;
wire tdo_o;

wire [7:0] reg_addr_o;
wire reg_wr_o;
wire [7:0] reg_wdata_o;
reg [7:0] reg_rdata_i;

integer errors;

jtag_core dut (
    .clk(clk),
    .rst_n(rst_n),
    .ena(ena),

    .tck_i(tck_i),
    .tms_i(tms_i),
    .tdi_i(tdi_i),
    .tdo_o(tdo_o),

    .reg_addr_o(reg_addr_o),
    .reg_wr_o(reg_wr_o),
    .reg_wdata_o(reg_wdata_o),
    .reg_rdata_i(reg_rdata_i)
);

initial begin
    clk = 1'b0;
    forever #20 clk = ~clk;  /* 25 MHz */
end

task jtag_clock;
    input tms;
    input tdi;
    begin
        tms_i = tms;
        tdi_i = tdi;

        /*
         * Leave these delays long relative to clk because jtag_core
         * synchronizes TCK/TMS/TDI into clk.
         */
        #400;
        tck_i = 1'b1;
        #400;
        tck_i = 1'b0;
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
             * tdo_o is driven after the sampled falling edge.
             * This test samples it just before the next bit cycle.
             */
            captured[i] = tdo_o;

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

reg [31:0] data;

initial begin
    $dumpfile("tb_jtag_core.vcd");
    $dumpvars(0, tb_jtag_core);

    errors = 0;

    rst_n = 1'b0;
    ena = 1'b0;
    tck_i = 1'b0;
    tms_i = 1'b1;
    tdi_i = 1'b0;
    reg_rdata_i = 8'h5A;

    #1000;

    rst_n = 1'b1;
    ena = 1'b1;

    #1000;

    $display("Test 1: IDCODE after reset");
    jtag_reset();
    shift_dr_32(32'h00000000, data);
    expect32(data, 32'h54544A31);

    $display("Test 2: REG_READ returns reg_rdata_i in low byte");
    jtag_reset();
    shift_ir(4'h3);
    reg_rdata_i = 8'hA6;
    shift_dr_32(32'h00000000, data);
    expect32(data & 32'h000000FF, 32'h000000A6);

    $display("Test 3: REG_ADDR update");
    jtag_reset();
    shift_ir(4'h2);
    shift_dr_32(32'h00000002, data);

    #1000;

    if (reg_addr_o !== 8'h02) begin
        $display("FAIL: reg_addr_o got 0x%02X expected 0x02", reg_addr_o);
        errors = errors + 1;
    end else begin
        $display("PASS: reg_addr_o got 0x%02X", reg_addr_o);
    end

    $display("Test 4: REG_WRITE update");
    jtag_reset();
    shift_ir(4'h4);
    shift_dr_32(32'h000000A5, data);

    #1000;

    if (reg_wdata_o !== 8'hA5) begin
        $display("FAIL: reg_wdata_o got 0x%02X expected 0xA5", reg_wdata_o);
        errors = errors + 1;
    end else begin
        $display("PASS: reg_wdata_o got 0x%02X", reg_wdata_o);
    end

    if (errors == 0) begin
        $display("PASS: all jtag_core tests passed");
    end else begin
        $display("FAIL: %0d errors", errors);
    end

    $finish;
end

endmodule

`default_nettype wire
