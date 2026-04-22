`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();
  initial begin
    $display("tb.v from tsky-UART-FSM-TRNG-Lab/test");
  end

  // Dump the signals to a FST file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
    #1;
  end

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

  // DUT: Replace tt_um_example with your module name:
  tt_um_gojimmypi user_project (

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
  ); /* tt_um_gojimmypi user_project */

    // CLOCK (runs forever)
    initial clk = 0;
    always #5 clk = ~clk;

    // WAVEFORM
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb);
    end

    // STIMULUS (THIS IS WHAT YOU WERE MISSING)
    initial begin
        rst_n = 0;
        ena   = 0;
        ui_in = 8'h00;
        uio_in = 8'h00;

        // let time advance
        #20;

        rst_n = 1;
        ena   = 1;

        #20;
        ui_in = 8'hAA;

        #20;
        uio_in = 8'h55;

        #100;

        $finish;
    end

    always @(posedge clk) begin
        if (rst_n) begin
            $display("t=%0t ui_in=%h uio_in=%h uo_out=%h",
                     $time, ui_in, uio_in, uo_out);
        end
    end
    always @(posedge clk) begin
        if (rst_n) begin
            $display("uio_out=%h uio_oe=%h", uio_out, uio_oe);
        end
    end
endmodule
