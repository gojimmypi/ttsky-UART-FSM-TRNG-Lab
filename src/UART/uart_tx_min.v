module uart_tx_min
#(
    parameter integer CLKS_PER_BIT = 217
)
(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] data_in,
    input  wire       start,
    output reg        tx,
    output reg        busy
);

    localparam [1:0] ST_IDLE  = 2'd0;
    localparam [1:0] ST_START = 2'd1;
    localparam [1:0] ST_DATA  = 2'd2;
    localparam [1:0] ST_STOP  = 2'd3;

    reg [1:0]  state;
    reg [7:0]  shift_reg;
    reg [3:0]  bit_index;
    reg [15:0] clk_count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= ST_IDLE;
            tx        <= 1'b1;
            busy      <= 1'b0;
            shift_reg <= 8'h00;
            bit_index <= 3'd0;
            clk_count <= 16'd0;
        end else begin
            case (state)
                ST_IDLE: begin
                    tx        <= 1'b1;
                    busy      <= 1'b0;
                    clk_count <= 16'd0;
                    bit_index <= 3'd0;

                    if (start) begin
                        shift_reg <= data_in;
                        busy      <= 1'b1;
                        tx        <= 1'b0;
                        state     <= ST_START;
                    end
                end

                ST_START: begin
                    busy <= 1'b1;

                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 16'd0;
                        tx        <= shift_reg[0];
                        shift_reg <= {1'b0, shift_reg[7:1]};
                        bit_index <= 3'd1;
                        state     <= ST_DATA;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                ST_DATA: begin
                    busy <= 1'b1;

                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 16'd0;

                        if (bit_index < 4'd8) begin
                            tx        <= shift_reg[0];
                            shift_reg <= {1'b0, shift_reg[7:1]};
                            bit_index <= bit_index + 1'b1;
                        end else begin
                            tx    <= 1'b1;
                            state <= ST_STOP;
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                ST_STOP: begin
                    busy <= 1'b1;

                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 16'd0;
                        state     <= ST_IDLE;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule
