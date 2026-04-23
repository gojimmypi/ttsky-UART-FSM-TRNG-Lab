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
