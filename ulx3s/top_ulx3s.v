`default_nettype none
`timescale 1ns/1ps

module top_ulx3s (
    input  wire        clk_25mhz,
    input  wire [6:0]  btn,
    output wire [7:0]  led
);

    wire [7:0] ui_in;
    wire [7:0] uio_in;
    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    wire rst_n;
    wire ena;

    /*
        Simple ULX3S-to-TT mapping for bring-up:

        btn[0] -> ui_in[0]
        btn[1] -> ui_in[1]
        ...
        btn[6] -> ui_in[6]
        ui_in[7] forced low

        uio_in fixed for now.
        rst_n forced high.
        ena forced high.

        LEDs show TT output bus.
    */
    assign ui_in = {1'b0, btn};
    assign uio_in = 8'h55;

    assign rst_n = 1'b1;
    assign ena   = 1'b1;

    tt_um_gojimmypi dut (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .ena(ena),
        .clk(clk_25mhz),
        .rst_n(rst_n)
    );

    assign led = uo_out;

endmodule

`default_nettype wire
