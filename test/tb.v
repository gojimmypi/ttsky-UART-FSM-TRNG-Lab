/*
 * Copyright (c) 2026 gojimmypi
 * SPDX-License-Identifier: Apache-2.0
 *
 * See ATTRIBUTION.md for third-party sources and credits.
 *
 * file: test/tb.v
 */
`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

`ifdef IS_MY_IVERILOG_SIMULATION
  // Dump the signals to a vcd (Value Change Dump) file. You can view it with gtkwave after 
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
  end
`else
  // the /.github/workflows/test.yaml expects tb.fst
  // see https://github.com/gojimmypi/ttsky-UART-FSM-TRNG-Lab/actions/runs/27104612809/job/79991381774
  // Dump the signals to a FST file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
    #1;
  end
`endif

  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;
`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

`ifndef TT_TOP_MODULE
    /* TT_TOP_MODULE should be defined in Makefile, extracted from root info.yaml
     * Otherwise replace tt_um_example with your module name:  */
    `define TT_TOP_MODULE tt_um_example
`endif

`TT_TOP_MODULE user_project (

      // Include power ports for the Gate Level test:
`ifdef GL_TEST
      .VPWR(VPWR),
      .VGND(VGND),
`endif

      .ui_in  (ui_in),    // Dedicated inputs
      .uo_out (uo_out),   // Dedicated outputs
      .uio_in (uio_in),   // IOs: Input path
      .uio_out(uio_out),  // IOs: Output path
      .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      .ena    (ena),      // enable - goes high when design is selected
      .clk    (clk),      // clock
      .rst_n  (rst_n)     // not reset
  );

  initial begin
    $display("tb.v simulation started");
  end

`ifndef COCOTB
  initial begin
    clk    = 1'b0;
    rst_n  = 1'b0;
    ena    = 1'b1;
    ui_in  = 8'h00;
    uio_in = 8'h00;
  end

  always #20 clk = ~clk;  // 25 MHz clock, 40 ns period

  initial begin
    // Hold reset low for a few cycles.
    repeat (10) @(posedge clk);
    rst_n = 1'b1;
    $display("reset released at t=%0t", $time);

    // UART RX idle high on ui_in[3].
    ui_in = 8'h08;
    repeat (100) @(posedge clk);

    // Change inputs so GTKWave has visible transitions.
    ui_in = 8'h18;
    repeat (100) @(posedge clk);

    ui_in = 8'h08;
    repeat (100) @(posedge clk);

  end

  initial begin
    // Safety timeout only.
    #10000000;  // 10 ms
    $display("tb.v simulation finished at t=%0t", $time);
    $finish;
  end
`endif /* COCOTB check */
endmodule

`default_nettype wire
