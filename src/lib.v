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
    reg [2:0]  bit_index;
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
    reg [2:0]  bit_index;
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

    wire [7:0] tx_byte;
    wire       tx_start;
    wire       tx_busy;

    wire [7:0] reg_ctrl;
    wire [7:0] reg_src;
    wire [7:0] reg_div;
    wire [7:0] reg_mode;
    wire [7:0] reg_oscen;

    wire [7:0] reg_status;
    wire [7:0] reg_rawlo;
    wire [7:0] reg_rawhi;
    wire       trng_bit;

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
        .data_in(tx_byte),
        .start(tx_start),
        .tx(uart_tx_o),
        .busy(tx_busy)
    );

    trng_cfg_ascii_core u_cfg
    (
        .clk(clk),
        .rst_n(rst_n),
        .rx_byte(rx_byte),
        .rx_valid(rx_valid),
        .tx_byte(tx_byte),
        .tx_start(tx_start),
        .tx_busy(tx_busy),
        .reg_ctrl(reg_ctrl),
        .reg_src(reg_src),
        .reg_div(reg_div),
        .reg_mode(reg_mode),
        .reg_oscen(reg_oscen),
        .reg_status(reg_status),
        .reg_rawlo(reg_rawlo),
        .reg_rawhi(reg_rawhi)
    );

    trng_stub u_trng
    (
        .clk(clk),
        .rst_n(rst_n),
        .reg_ctrl(reg_ctrl),
        .reg_src(reg_src),
        .reg_div(reg_div),
        .reg_mode(reg_mode),
        .reg_oscen(reg_oscen),
        .reg_status(reg_status),
        .reg_rawlo(reg_rawlo),
        .reg_rawhi(reg_rawhi),
        .trng_bit(trng_bit)
    );

    assign reg_ctrl_o   = reg_ctrl;
    assign reg_src_o    = reg_src;
    assign reg_div_o    = reg_div;
    assign reg_mode_o   = reg_mode;
    assign reg_oscen_o  = reg_oscen;
    assign reg_status_o = reg_status;
    assign reg_rawlo_o  = reg_rawlo;
    assign reg_rawhi_o  = reg_rawhi;
    assign trng_bit_o   = trng_bit;

endmodule


module tt_um_uart_trng_ascii
(
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    localparam integer CLKS_PER_BIT = 217;

    wire [7:0] reg_ctrl;
    wire [7:0] reg_src;
    wire [7:0] reg_div;
    wire [7:0] reg_mode;
    wire [7:0] reg_oscen;
    wire [7:0] reg_status;
    wire [7:0] reg_rawlo;
    wire [7:0] reg_rawhi;
    wire       trng_bit;
    wire       uart_tx;

    wire unused_ok;
    assign unused_ok = &{ena, uio_in};

    uart_trng_ascii_core
    #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    )
    u_core
    (
        .clk(clk),
        .rst_n(rst_n),
        .uart_rx_i(ui_in[3]),
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

    assign uo_out[4] = uart_tx;
    assign uo_out[0] = trng_bit;
    assign uo_out[1] = reg_status[0];
    assign uo_out[2] = reg_status[1];
    assign uo_out[3] = reg_status[2];
    assign uo_out[5] = reg_rawlo[0];
    assign uo_out[6] = reg_rawlo[1];
    assign uo_out[7] = reg_rawlo[2];

    assign uio_out = reg_rawhi;
    assign uio_oe  = 8'hFF;

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