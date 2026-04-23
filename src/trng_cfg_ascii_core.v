module trng_cfg_ascii_core
(
    input  wire       clk,
    input  wire       rst_n,

    input  wire [7:0] rx_byte,
    input  wire       rx_valid,

    output reg  [7:0] tx_byte,
    output reg        tx_start,
    input  wire       tx_busy,

    output reg  [7:0] reg_ctrl,
    output reg  [7:0] reg_src,
    output reg  [7:0] reg_div,
    output reg  [7:0] reg_mode,
    output reg  [7:0] reg_oscen,

    input  wire [7:0] reg_status,
    input  wire [7:0] reg_rawlo,
    input  wire [7:0] reg_rawhi
);

    localparam [4:0] ST_IDLE       = 5'd0;
    localparam [4:0] ST_ARG1       = 5'd1;
    localparam [4:0] ST_ARG2       = 5'd2;
    localparam [4:0] ST_WAIT_CR    = 5'd3;
    localparam [4:0] ST_Q_R        = 5'd4;
    localparam [4:0] ST_Q_N        = 5'd5;
    localparam [4:0] ST_Q_EQ       = 5'd6;
    localparam [4:0] ST_Q_HI       = 5'd7;
    localparam [4:0] ST_Q_LO       = 5'd8;
    localparam [4:0] ST_Q_CR       = 5'd9;
    localparam [4:0] ST_Q_O        = 5'd10;
    localparam [4:0] ST_Q_K        = 5'd11;
    localparam [4:0] ST_Q_ERR      = 5'd12;
    localparam [4:0] ST_WAIT_SEND  = 5'd13;

    reg [4:0] state;
    reg [7:0] cmd;
    reg [3:0] hex1;
    reg [3:0] hex2;
    reg       need_two_digits;
    reg [2:0] read_addr;
    reg [7:0] reply_value;

    reg [7:0] queued_tx_byte;
    reg       queued_tx_valid;

    function is_hex;
        input [7:0] c;
        begin
            if ((c >= "0") && (c <= "9")) begin
                is_hex = 1'b1;
            end else if ((c >= "A") && (c <= "F")) begin
                is_hex = 1'b1;
            end else begin
                is_hex = 1'b0;
            end
        end
    endfunction

    function [3:0] hex_value;
        input [7:0] c;
        begin
            if ((c >= "0") && (c <= "9")) begin
                hex_value = c - "0";
            end else if ((c >= "A") && (c <= "F")) begin
                hex_value = c - "A" + 4'd10;
            end else begin
                hex_value = 4'h0;
            end
        end
    endfunction

    function [7:0] read_reg;
        input [2:0] addr;
        begin
            case (addr)
                3'd0: read_reg = reg_ctrl;
                3'd1: read_reg = reg_src;
                3'd2: read_reg = reg_div;
                3'd3: read_reg = reg_mode;
                3'd4: read_reg = reg_oscen;
                3'd5: read_reg = reg_status;
                3'd6: read_reg = reg_rawlo;
                3'd7: read_reg = reg_rawhi;
                default: read_reg = 8'h00;
            endcase
        end
    endfunction

    function [7:0] to_hex_ascii;
        input [3:0] nib;
        begin
            if (nib < 10) begin
                to_hex_ascii = "0" + nib;
            end else begin
                to_hex_ascii = "A" + (nib - 10);
            end
        end
    endfunction

    task do_write;
        input [7:0] c;
        input [7:0] value;
        begin
            case (c)
                "E": reg_ctrl[0]   <= value[0];
                "S": reg_src[1:0]  <= value[1:0];
                "D": reg_div       <= value;
                "V": reg_ctrl[1]   <= value[0];
                "W": reg_ctrl[2]   <= value[0];
                "M": reg_mode      <= value;
                "O": reg_oscen     <= value;
                default: begin end
            endcase
        end
    endtask

    task queue_tx;
        input [7:0] c;
        begin
            queued_tx_byte  <= c;
            queued_tx_valid <= 1'b1;
        end
    endtask

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state           <= ST_IDLE;
            cmd             <= 8'h00;
            hex1            <= 4'h0;
            hex2            <= 4'h0;
            need_two_digits <= 1'b0;
            read_addr       <= 3'd0;
            reply_value     <= 8'h00;

            queued_tx_byte  <= 8'h00;
            queued_tx_valid <= 1'b0;
            tx_byte         <= 8'h00;
            tx_start        <= 1'b0;

            reg_ctrl        <= 8'h00;
            reg_src         <= 8'h00;
            reg_div         <= 8'h10;
            reg_mode        <= 8'h00;
            reg_oscen       <= 8'h01;
        end else begin
            tx_start <= 1'b0;

            if (queued_tx_valid && !tx_busy) begin
                tx_byte         <= queued_tx_byte;
                tx_start        <= 1'b1;
                queued_tx_valid <= 1'b0;
            end

            case (state)
                ST_IDLE: begin
                    if (rx_valid) begin
                        if (rx_byte == 8'h0A) begin
                            state <= ST_IDLE;
                        end else if ((rx_byte == "E") ||
                                     (rx_byte == "S") ||
                                     (rx_byte == "V") ||
                                     (rx_byte == "W")) begin
                            cmd             <= rx_byte;
                            need_two_digits <= 1'b0;
                            state           <= ST_ARG1;
                        end else if ((rx_byte == "D") ||
                                     (rx_byte == "M") ||
                                     (rx_byte == "O")) begin
                            cmd             <= rx_byte;
                            need_two_digits <= 1'b1;
                            state           <= ST_ARG1;
                        end else if (rx_byte == "R") begin
                            cmd             <= rx_byte;
                            need_two_digits <= 1'b0;
                            state           <= ST_ARG1;
                        end else begin
                            state <= ST_Q_ERR;
                        end
                    end
                end

                ST_ARG1: begin
                    if (rx_valid) begin
                        if (is_hex(rx_byte)) begin
                            hex1 <= hex_value(rx_byte);

                            if (cmd == "R") begin
                                read_addr <= hex_value(rx_byte);
                                state <= ST_WAIT_CR;
                            end else if (need_two_digits) begin
                                state <= ST_ARG2;
                            end else begin
                                state <= ST_WAIT_CR;
                            end
                        end else begin
                            state <= ST_Q_ERR;
                        end
                    end
                end

                ST_ARG2: begin
                    if (rx_valid) begin
                        if (is_hex(rx_byte)) begin
                            hex2  <= hex_value(rx_byte);
                            state <= ST_WAIT_CR;
                        end else begin
                            state <= ST_Q_ERR;
                        end
                    end
                end

                ST_WAIT_CR: begin
                    if (rx_valid) begin
                        if (rx_byte == 8'h0A) begin
                            state <= ST_WAIT_CR;
                        end else if (rx_byte == 8'h0D) begin
                            if (cmd == "R") begin
                                reply_value <= read_reg(read_addr);
                                state <= ST_Q_R;
                            end else begin
                                if (need_two_digits) begin
                                    do_write(cmd, {hex1, hex2});
                                end else begin
                                    do_write(cmd, {4'h0, hex1});
                                end
                                state <= ST_Q_O;
                            end
                        end else begin
                            state <= ST_Q_ERR;
                        end
                    end
                end

                ST_Q_R: begin
                    if (!queued_tx_valid) begin
                        queue_tx("R");
                        state <= ST_WAIT_SEND;
                    end
                end

                ST_Q_N: begin
                    if (!queued_tx_valid) begin
                        queue_tx(to_hex_ascii({1'b0, read_addr}));
                        state <= ST_WAIT_SEND;
                    end
                end

                ST_Q_EQ: begin
                    if (!queued_tx_valid) begin
                        queue_tx("=");
                        state <= ST_WAIT_SEND;
                    end
                end

                ST_Q_HI: begin
                    if (!queued_tx_valid) begin
                        queue_tx(to_hex_ascii(reply_value[7:4]));
                        state <= ST_WAIT_SEND;
                    end
                end

                ST_Q_LO: begin
                    if (!queued_tx_valid) begin
                        queue_tx(to_hex_ascii(reply_value[3:0]));
                        state <= ST_WAIT_SEND;
                    end
                end

                ST_Q_CR: begin
                    if (!queued_tx_valid) begin
                        queue_tx(8'h0D);
                        state <= ST_WAIT_SEND;
                    end
                end

                ST_Q_O: begin
                    if (!queued_tx_valid) begin
                        queue_tx("O");
                        state <= ST_WAIT_SEND;
                    end
                end

                ST_Q_K: begin
                    if (!queued_tx_valid) begin
                        queue_tx("K");
                        state <= ST_WAIT_SEND;
                    end
                end

                ST_Q_ERR: begin
                    if (!queued_tx_valid) begin
                        queue_tx("?");
                        state <= ST_WAIT_SEND;
                    end
                end

                ST_WAIT_SEND: begin
                    if (!queued_tx_valid && !tx_busy) begin
                        case (state)
                            default: begin
                            end
                        endcase
                    end

                    if (!queued_tx_valid && !tx_busy) begin
                        if (cmd == "R") begin
                            if (tx_byte == "R") begin
                                state <= ST_Q_N;
                            end else if (tx_byte == to_hex_ascii({1'b0, read_addr})) begin
                                state <= ST_Q_EQ;
                            end else if (tx_byte == "=") begin
                                state <= ST_Q_HI;
                            end else if (tx_byte == to_hex_ascii(reply_value[7:4])) begin
                                state <= ST_Q_LO;
                            end else if (tx_byte == to_hex_ascii(reply_value[3:0])) begin
                                state <= ST_Q_CR;
                            end else begin
                                state <= ST_IDLE;
                            end
                        end else begin
                            if (tx_byte == "O") begin
                                state <= ST_Q_K;
                            end else if (tx_byte == "K") begin
                                state <= ST_Q_CR;
                            end else if (tx_byte == "?") begin
                                state <= ST_Q_CR;
                            end else begin
                                state <= ST_IDLE;
                            end
                        end
                    end
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase

            if (state == ST_Q_CR && !queued_tx_valid && !tx_busy && tx_byte == 8'h0D) begin
                state <= ST_IDLE;
            end
        end
    end

endmodule
