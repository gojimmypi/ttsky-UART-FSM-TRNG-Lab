`default_nettype none
`timescale 1ns/1ps

module top_ulx3s (
    input  wire       clk_25mhz,
    input  wire [6:0] btn,
    output wire [7:0] led,
    input  wire       uart_rx_pin,
    output wire       uart_tx_pin
);

    wire rst_n;

    wire [7:0] reg_ctrl_o;
    wire [7:0] reg_src_o;
    wire [7:0] reg_div_o;
    wire [7:0] reg_mode_o;
    wire [7:0] reg_oscen_o;
    wire [7:0] reg_status_o;
    wire [7:0] reg_rawlo_o;
    wire [7:0] reg_rawhi_o;
    wire       trng_bit_o;

    reg uart_rx_meta;
    reg uart_rx_sync;

    assign rst_n = btn[0];

    always @(posedge clk_25mhz) begin
        uart_rx_meta <= uart_rx_pin;
        uart_rx_sync <= uart_rx_meta;
    end

    uart_trng_ascii_core
    #(
        .CLKS_PER_BIT(217)
    )
    u_core
    (
        .clk(clk_25mhz),
        .rst_n(rst_n),
        .uart_rx_i(uart_rx_sync),
        .uart_tx_o(uart_tx_pin),

        .reg_ctrl_o(reg_ctrl_o),
        .reg_src_o(reg_src_o),
        .reg_div_o(reg_div_o),
        .reg_mode_o(reg_mode_o),
        .reg_oscen_o(reg_oscen_o),

        .reg_status_o(reg_status_o),
        .reg_rawlo_o(reg_rawlo_o),
        .reg_rawhi_o(reg_rawhi_o),
        .trng_bit_o(trng_bit_o)
    );

//    assign led[0] = uart_rx_sync;
//    assign led[1] = uart_tx_pin;
//    assign led[2] = reg_status_o[1];
//    assign led[3] = reg_status_o[2];
//    assign led[4] = reg_status_o[3];
//    assign led[5] = reg_rawlo_o[0];
//    assign led[6] = reg_rawlo_o[1];
//    assign led[7] = reg_rawlo_o[2];

endmodule

`default_nettype wire