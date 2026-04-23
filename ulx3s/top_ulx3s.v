`default_nettype none
`timescale 1ns/1ps

module top_ulx3s (
    input  wire        clk_25mhz,
    input  wire [6:0]  btn,
    output wire [7:0]  led,
    input  wire        uart_rx_pin,
    output wire        uart_tx_pin
);

    wire [7:0] ui_in;
    wire [7:0] uio_in;
    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    wire rst_n;
    wire ena;

    reg uart_rx_meta;
    reg uart_rx_sync;

    assign rst_n = 1'b1;
    assign ena   = 1'b1;

    always @(posedge clk_25mhz) begin
        uart_rx_meta <= uart_rx_pin;
        uart_rx_sync <= uart_rx_meta;
    end

    // Map UART RX into TT input
    assign ui_in = {4'b0000, uart_rx_sync, 3'b000};

    assign uio_in = 8'h00;

    tt_um_gojimmypi dut
    (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .ena(ena),
        .clk(clk_25mhz),
        .rst_n(rst_n)  // TODO - add a reset button and connect it here instead of hardcoding rst_n=1
    );

    `ifdef FORCE_LOOPBACK
        // Loopback UART TX to RX for testing
        initial $display("FORCE_LOOPBACK ENABLED");
        assign uart_tx_pin = uart_rx_sync;  
    `else
        initial $display("FORCE_LOOPBACK DISABLED");
        assign uart_tx_pin = uo_out[4];
        // assign uart_tx_pin = 1'b0;
        // assign uart_tx_pin = 1'b1;
    `endif /* FORCE_LOOPBACK */

    // Debug
    assign led = uo_out;
    // assign led = 8'h00;

endmodule

`default_nettype wire
