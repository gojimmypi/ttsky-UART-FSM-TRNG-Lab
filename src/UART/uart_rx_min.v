module uart_rx_min
#(
    parameter integer CLKS_PER_BIT = 217
)
(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx,
    output reg [7:0]  data_out,
    output reg        data_valid
); 

    localparam [1:0] ST_IDLE  = 2'd0;
    localparam [1:0] ST_START = 2'd1;
    localparam [1:0] ST_DATA  = 2'd2;
    localparam [1:0] ST_STOP  = 2'd3;

    reg [1:0]  state;
    reg        rx_meta;
    reg        rx_sync;
    reg [15:0] clk_count;
    reg [3:0]  bit_index;
    reg [7:0]  shift_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end else begin
            rx_meta <= rx;
            rx_sync <= rx_meta;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= ST_IDLE;
            clk_count  <= 16'd0;
            bit_index  <= 3'd0;
            shift_reg  <= 8'h00;
            data_out   <= 8'h00;
            data_valid <= 1'b0;
        end else begin
            data_valid <= 1'b0;

            case (state)
                ST_IDLE: begin
                    clk_count <= 16'd0;
                    bit_index <= 3'd0;

                    if (rx_sync == 1'b0) begin
                        state     <= ST_START;
                        clk_count <= 16'd0;
                    end
                end

                ST_START: begin
                    if (clk_count == ((CLKS_PER_BIT - 1) >> 1)) begin
                        if (rx_sync == 1'b0) begin
                            clk_count <= 16'd0;
                            bit_index <= 3'd0;
                            state     <= ST_DATA;
                        end else begin
                            state <= ST_IDLE;
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                ST_DATA: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 16'd0;
                        shift_reg[bit_index] <= rx_sync;

                        if (bit_index == 3'd7) begin
                            state <= ST_STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                ST_STOP: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 16'd0;

                        if (rx_sync == 1'b1) begin
                            data_out   <= shift_reg;
                            data_valid <= 1'b1;
                        end

                        state <= ST_IDLE;
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