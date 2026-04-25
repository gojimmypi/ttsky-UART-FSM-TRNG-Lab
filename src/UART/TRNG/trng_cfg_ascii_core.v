/*
 * Copyright (c) 2026 gojimmypi
 * SPDX-License-Identifier: Apache-2.0
 *
 * file: trng_cfg_ascii_core.v
 *
 * ASCII command parser and register front-end for the UART/TRNG experiment.
 *
 * Purpose:
 * - Receives decoded UART bytes from uart_rx_min.
 * - Interprets a very small ASCII command set.
 * - Updates configuration registers or reads them back.
 * - Generates ASCII replies using uart_tx_min.
 *
 * High-level command format:
 * - Single-nibble write commands: Ex, Sx, Vx, Wx followed by CR
 * - Two-nibble write commands: Dxxy, Mxy, Oxy followed by CR
 * - Register reads: Rx followed by CR, where x is 0..7
 * - Version query: V followed by CR
 *
 * Example transactions:
 * - E1<CR>     : set enable bit
 * - D10<CR>    : set divider register to 0x10
 * - R6<CR>     : read register 6, replies R6=hh<CR>
 * - V<CR>      : replies Version 1.2.0 4/23/2026<CR>
 *
 * Reply format:
 * - Successful write: OK<CR>
 * - Successful read : Rn=HH<CR>
 * - Version query   : Version 1.2.0 4/23/2026<CR>
 * - Parse/error     : ?<CR>
 */
`default_nettype none

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

    /*
     * Parser / reply state machine.
     * Separate states are used for command collection and for multi-character
     * response generation so the logic can serialize through one UART TX path.
     */
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
    localparam [4:0] ST_Q_STR      = 5'd14;

    localparam integer VERSION_LEN = 23;
    localparam [8*VERSION_LEN-1:0] VERSION_STR = "Version 1.2.0 4/23/2026";

    reg [4:0] state;
    reg [4:0] next_state_after_send;

    /*
     * cmd records the operation letter.
     * hex1/hex2 hold parsed ASCII hex nibbles until CR arrives.
     */
    reg [7:0] cmd;
    reg [3:0] hex1;
    reg [3:0] hex2;
    reg       need_two_digits;
    reg [2:0] read_addr;
    reg [7:0] reply_value;

    /*
     * One-byte transmit queue.
     * The parser loads queued_tx_byte, and the front-end launches it only when
     * the downstream UART TX is idle.
     */
    reg [7:0] queued_tx_byte;
    reg       queued_tx_valid;

    /*
     * Generic string send support for multi-character replies such as version.
     * active_str holds the current packed ASCII string, str_len is the number
     * of valid characters, and str_index walks through the string one byte at
     * a time.
     */
    reg [8*VERSION_LEN-1:0] active_str;
    reg [5:0] str_index;
    reg [5:0] str_len;

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
                /* hex_value = c - "0"; 2 each 8-bit literals to avoid Verilog treating the result as a full byte instead of a nibble. */
                // hex_value = (c - 8'd48) & 8'h0F;  // "0" = 48
                hex_value = c[3:0];
            end else if ((c >= "A") && (c <= "F")) begin
                // hex_value = c - "A" + 4'd10;
                // hex_value = (c - 8'd65 + 4'd10) & 8'h0F;  // "A" = 65
                hex_value = c[3:0] + 4'd9;
            end else begin
                hex_value = 4'h0;
            end
        end
    endfunction

    /*
     * Address map used by the Rn read command.
     * 0..4 are writable configuration registers.
     * 5..7 are read-only status/data registers coming back from the TRNG side.
     */
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

    /* Convert a nibble to ASCII hex for readback replies. */
function [7:0] to_hex_ascii;
    input [3:0] nib;
    begin
        if (nib < 4'd10) begin
            //           =  8'd48  + nib;           // '0' + nib
            to_hex_ascii = {4'b0011, nib};          // '0'..'9'
        end else begin
            //           =  8'd55  + nib;           // 'A' - 10 + nib  (65 - 10 = 55)
            to_hex_ascii = {4'b0100, nib} + 8'd7;   // 'A'..'F'
        end
    end
endfunction

    /*
     * Return one ASCII character from a packed string.
     * Index 0 returns the leftmost character in the packed constant.
     */
    function [7:0] str_get;
        input [8*VERSION_LEN-1:0] str;
        input [5:0] idx;
        reg [8*VERSION_LEN-1:0] shifted;
        reg [7:0] shift_amt;
        begin
            shift_amt = (VERSION_LEN[7:0] - 8'd1 - {2'd0, idx}) << 3;
            shifted = str >> shift_amt;
            str_get = shifted[7:0];
        end
    endfunction

    /*
     * Write decoded values into specific register fields.
     * Some commands write only selected bits while others write a full byte.
     */
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

    /* Queue one reply character. */
    task queue_tx;
        input [7:0] c;
        begin
            queued_tx_byte  <= c;
            queued_tx_valid <= 1'b1;
        end
    endtask

    /*
     * Start sending a packed ASCII string using the generic string serializer.
     * The actual characters are launched through the normal one-byte queue.
     */
    task start_string;
        input [((8 * VERSION_LEN) - 1):0] str;
        input [5:0] len;
        begin
            active_str <= str;
            str_len    <= len;
            str_index  <= 6'd0;
            state      <= ST_Q_STR;
        end
    endtask

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state                 <= ST_IDLE;
            next_state_after_send <= ST_IDLE;
            cmd                   <= 8'h00;
            hex1                  <= 4'h0;
            hex2                  <= 4'h0;
            need_two_digits       <= 1'b0;
            read_addr             <= 3'd0;
            reply_value           <= 8'h00;

            queued_tx_byte        <= 8'h00;
            queued_tx_valid       <= 1'b0;
            tx_byte               <= 8'h00;
            tx_start              <= 1'b0;

            active_str            <= {(8 * VERSION_LEN){1'b0}};
            str_index             <= 6'd0;
            str_len               <= 6'd0;

            /* Default power-on register values for bring-up. */
            reg_ctrl              <= 8'h00;
            reg_src               <= 8'h00;
            reg_div               <= 8'h10;
            reg_mode              <= 8'h00;
            reg_oscen             <= 8'h01;
        end else begin
            /* tx_start is a one-clock pulse into uart_tx_min. */
            tx_start <= 1'b0;

            /*
             * Launch a queued reply byte only when the UART transmitter is free.
             * This decouples parser sequencing from the transmit bit timing.
             */
            if (queued_tx_valid && !tx_busy) begin
                tx_byte         <= queued_tx_byte;
                tx_start        <= 1'b1;
                queued_tx_valid <= 1'b0;
            end

            case (state)
                ST_IDLE: begin
                    if (rx_valid) begin
                        /* Ignore LF so terminals sending CRLF still work. */
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
                        /*
                         * Bare V<CR> is treated as a version query.
                         * Vx<CR> still retains its original single-nibble write
                         * behavior for reg_ctrl[1].
                         */
                        if ((cmd == "V") && (rx_byte == 8'h0A)) begin
                            state <= ST_ARG1;
                        end else if ((cmd == "V") && (rx_byte == 8'h0D)) begin
                            start_string(VERSION_STR, VERSION_LEN[5:0]);
                        end else if (is_hex(rx_byte)) begin
                            hex1 <= hex_value(rx_byte);

                            if (cmd == "R") begin
                                /* Only registers 0..7 are addressable. */
                                if (hex_value(rx_byte) < 4'd8) begin
                                    read_addr <= hex_value(rx_byte);
                                    state <= ST_WAIT_CR;
                                end else begin
                                    state <= ST_Q_ERR;
                                end
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
                        /* Again ignore LF so CRLF is accepted. */
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

                /* Read reply is serialized as: R n = H H CR */
                ST_Q_R: begin
                    if (!queued_tx_valid) begin
                        queue_tx("R");
                        next_state_after_send <= ST_Q_N;
                        state <= ST_WAIT_SEND;
                    end
                end

                ST_Q_N: begin
                    if (!queued_tx_valid) begin
                        queue_tx(to_hex_ascii({1'b0, read_addr}));
                        next_state_after_send <= ST_Q_EQ;
                        state <= ST_WAIT_SEND;
                    end
                end

                ST_Q_EQ: begin
                    if (!queued_tx_valid) begin
                        queue_tx("=");
                        next_state_after_send <= ST_Q_HI;
                        state <= ST_WAIT_SEND;
                    end
                end

                ST_Q_HI: begin
                    if (!queued_tx_valid) begin
                        queue_tx(to_hex_ascii(reply_value[7:4]));
                        next_state_after_send <= ST_Q_LO;
                        state <= ST_WAIT_SEND;
                    end
                end

                ST_Q_LO: begin
                    if (!queued_tx_valid) begin
                        queue_tx(to_hex_ascii(reply_value[3:0]));
                        next_state_after_send <= ST_Q_CR;
                        state <= ST_WAIT_SEND;
                    end
                end

                ST_Q_CR: begin
                    if (!queued_tx_valid) begin
                        queue_tx(8'h0D);
                        next_state_after_send <= ST_IDLE;
                        state <= ST_WAIT_SEND;
                    end
                end

                /* Write reply is serialized as: O K CR */
                ST_Q_O: begin
                    if (!queued_tx_valid) begin
                        queue_tx("O");
                        next_state_after_send <= ST_Q_K;
                        state <= ST_WAIT_SEND;
                    end
                end

                ST_Q_K: begin
                    if (!queued_tx_valid) begin
                        queue_tx("K");
                        next_state_after_send <= ST_Q_CR;
                        state <= ST_WAIT_SEND;
                    end
                end

                /* Generic parser error reply. */
                ST_Q_ERR: begin
                    if (!queued_tx_valid) begin
                        queue_tx("?");
                        next_state_after_send <= ST_Q_CR;
                        state <= ST_WAIT_SEND;
                    end
                end

                /*
                 * Generic packed-string sender.
                 * Characters are emitted one at a time through the normal queue
                 * and ST_WAIT_SEND handshake path.
                 */
                ST_Q_STR: begin
                    if (!queued_tx_valid) begin
                        if (str_index < str_len) begin
                            queue_tx(str_get(active_str, str_index));
                            str_index <= str_index + 1'b1;
                            next_state_after_send <= ST_Q_STR;
                            state <= ST_WAIT_SEND;
                        end else begin
                            queue_tx(8'h0D);
                            next_state_after_send <= ST_IDLE;
                            state <= ST_WAIT_SEND;
                        end
                    end
                end

                /*
                 * Stay here until the queued byte has been accepted and the UART
                 * transmitter is no longer busy. Then continue with the next
                 * response character.
                 */
                ST_WAIT_SEND: begin
                    if (!queued_tx_valid && !tx_busy) begin
                        state <= next_state_after_send;
                    end
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule

`default_nettype wire
