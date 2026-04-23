module uart_trng_ascii_core
#(
    parameter integer CLKS_PER_BIT = 217
)
(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       uart_rx_i,
    output wire       uart_tx_o,

    output wire [7:0] reg_ctrl_o,
    output wire [7:0] reg_src_o,
    output wire [7:0] reg_div_o,
    output wire [7:0] reg_mode_o,
    output wire [7:0] reg_oscen_o,

    output wire [7:0] reg_status_o,
    output wire [7:0] reg_rawlo_o,
    output wire [7:0] reg_rawhi_o,
    output wire       trng_bit_o
);

    wire [7:0] rx_byte;
    wire       rx_valid;

    reg  [7:0] tx_byte_r;
    reg        tx_start_r;
    wire       tx_busy;

    reg  [7:0] reg_ctrl_r;
    reg  [7:0] reg_src_r;
    reg  [7:0] reg_div_r;
    reg  [7:0] reg_mode_r;
    reg  [7:0] reg_oscen_r;

    reg  [7:0] reg_status_r;
    reg  [7:0] reg_rawlo_r;
    reg  [7:0] reg_rawhi_r;
    reg        trng_bit_r;

    uart_rx_min
    #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    )
    u_rx
    (
        .clk(clk),
        .rst_n(rst_n),
        .rx(uart_rx_i),
        .data_out(rx_byte),
        .data_valid(rx_valid)
    );

    uart_tx_min
    #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    )
    u_tx
    (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(tx_byte_r),
        .start(tx_start_r),
        .tx(uart_tx_o),
        .busy(tx_busy)
    );

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_byte_r    <= 8'h00;
        tx_start_r   <= 1'b0;

        reg_ctrl_r   <= 8'h00;
        reg_src_r    <= 8'h00;
        reg_div_r    <= 8'h10;
        reg_mode_r   <= 8'h00;
        reg_oscen_r  <= 8'h01;

        reg_status_r <= 8'h00;
        reg_rawlo_r  <= 8'h00;
        reg_rawhi_r  <= 8'h00;
        trng_bit_r   <= 1'b0;
    end else begin
        tx_start_r <= 1'b0;

        reg_status_r[0]   <= uart_rx_i;
        reg_status_r[1]   <= rx_valid;
        reg_status_r[2]   <= tx_start_r;
        reg_status_r[3]   <= tx_busy;
        reg_status_r[7:4] <= 4'h0;

        if (rx_valid_pulse && !tx_busy) begin
            tx_byte_r   <= rx_byte;
            tx_start_r  <= 1'b1;

            reg_rawlo_r <= rx_byte;
            reg_rawhi_r <= rx_byte;
            trng_bit_r  <= rx_byte[0];
        end
    end
end

reg rx_valid_d;
wire rx_valid_pulse;

assign rx_valid_pulse = rx_valid && !rx_valid_d;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_valid_d <= 1'b0;
    end else begin
        rx_valid_d <= rx_valid;
    end
end

    assign reg_ctrl_o   = reg_ctrl_r;
    assign reg_src_o    = reg_src_r;
    assign reg_div_o    = reg_div_r;
    assign reg_mode_o   = reg_mode_r;
    assign reg_oscen_o  = reg_oscen_r;
    assign reg_status_o = reg_status_r;
    assign reg_rawlo_o  = reg_rawlo_r;
    assign reg_rawhi_o  = reg_rawhi_r;
    assign trng_bit_o   = trng_bit_r;

//debug
assign led[0] = uart_rx_sync;
assign led[1] = uart_tx_pin;
assign led[2] = rx_valid;
assign led[3] = tx_start_r;
assign led[4] = tx_busy;

endmodule
