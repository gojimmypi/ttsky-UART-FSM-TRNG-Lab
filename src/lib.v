


module trng_stub
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

    reg [15:0] sample_ctr;
    reg [15:0] lfsr;
    wire trng_enable;

    assign trng_enable = reg_ctrl[0];
    assign trng_bit = lfsr[0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_ctr <= 16'h0000;
            lfsr       <= 16'h1ACE;
            reg_status <= 8'h00;
            reg_rawlo  <= 8'h00;
            reg_rawhi  <= 8'h00;
        end else begin
            reg_status[0]   <= trng_enable;
            reg_status[1]   <= reg_ctrl[1];
            reg_status[2]   <= reg_ctrl[2];
            reg_status[4:3] <= reg_src[1:0];
            reg_status[7:5] <= reg_mode[2:0];

            if (trng_enable) begin
                if (sample_ctr >= {8'h00, reg_div}) begin
                    sample_ctr <= 16'h0000;
                    lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10] ^ reg_oscen[0] ^ reg_src[0]};
                    reg_rawlo <= lfsr[7:0];
                    reg_rawhi <= lfsr[15:8];
                end else begin
                    sample_ctr <= sample_ctr + 1'b1;
                end
            end
        end
    end

endmodule



module ulx3s_uart_trng_ascii_top
#(
    parameter integer CLKS_PER_BIT = 217
)
(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       uart_rx,
    output wire       uart_tx,
    output wire [7:0] led
);

    wire [7:0] reg_ctrl;
    wire [7:0] reg_src;
    wire [7:0] reg_div;
    wire [7:0] reg_mode;
    wire [7:0] reg_oscen;
    wire [7:0] reg_status;
    wire [7:0] reg_rawlo;
    wire [7:0] reg_rawhi;
    wire       trng_bit;

    uart_trng_ascii_core
    #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    )
    u_core
    (
        .clk(clk),
        .rst_n(rst_n),
        .uart_rx_i(uart_rx),
        .uart_tx_o(uart_tx),
        .reg_ctrl_o(reg_ctrl),
        .reg_src_o(reg_src),
        .reg_div_o(reg_div),
        .reg_mode_o(reg_mode),
        .reg_oscen_o(reg_oscen),
        .reg_status_o(reg_status),
        .reg_rawlo_o(reg_rawlo),
        .reg_rawhi_o(reg_rawhi),
        .trng_bit_o(trng_bit)
    );

    assign led = reg_rawlo;

endmodule