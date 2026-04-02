`timescale 1ns / 1ps

module aes_core (
    input  logic         clk,
    input  logic         aresetn,
    input  logic         start,
    input  logic [127:0] key,
    input  logic         key_init_start,
    input  aes_types_pkg::state_t plaintext,
    output logic         busy,
    output logic         key_ready,
    output aes_types_pkg::state_t ciphertext,
    output logic         data_valid
);

    import aes_types_pkg::*;

    state_t state_reg, state_next;
    state_t state_sub_bytes;
    state_e current_state, next_state;
    logic [3:0] round_count, round_count_next;
    logic       data_valid_reg;

    logic [127:0] round_key;

    aes_key_expand key_expander (
        .clk(clk),
        .aresetn(aresetn),
        .key_init_start(key_init_start),
        .key_in(key),
        .round(round_count),
        .round_key(round_key),
        .key_ready(key_ready)
    );

    genvar i, j;
    generate
        for (i = 0; i < 4; i++) begin : sbox_rows
            for (j = 0; j < 4; j++) begin : sbox_cols
                aes_sbox sbox_inst (
                    .sbox_in(state_reg[i][j]),
                    .sbox_out(state_sub_bytes[i][j])
                );
            end
        end
    endgenerate

    always_ff @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            current_state <= IDLE;
            round_count   <= 4'd0;
            state_reg     <= '0;
            data_valid_reg<= 1'b0;
        end else begin
            current_state <= next_state;
            round_count   <= round_count_next;
            state_reg     <= state_next;
            data_valid_reg<= (next_state == DONE);
        end
    end

    always_comb begin
        next_state       = current_state;
        round_count_next = round_count;
        state_next       = state_reg;
        busy             = 1'b1;

        case (current_state)
            IDLE: begin
                busy = 1'b0;

                if (start) begin
                    next_state = INIT_ROUND;
                end
            end

            INIT_ROUND: begin
                state_next = plaintext;
                round_count_next = 4'd0;
                next_state = ADD_KEY;
            end

            ADD_KEY: begin
                for (int r = 0; r < 4; r++) begin
                    for (int c = 0; c < 4; c++) begin
                        state_next[r][c] = state_reg[r][c] ^ round_key[r*32 + c*8 +: 8];
                    end
                end

                if (round_count == 10) begin
                    next_state = DONE;
                end else begin
                    next_state = SUB_BYTES;
                end
            end

            SUB_BYTES: begin
                state_next = state_sub_bytes;
                next_state = SHIFT_ROWS;
            end

            SHIFT_ROWS: begin
                state_next[0] = state_reg[0];
                state_next[1] = {state_reg[1][2], state_reg[1][1], state_reg[1][0], state_reg[1][3]};
                state_next[2] = {state_reg[2][1], state_reg[2][0], state_reg[2][3], state_reg[2][2]};
                state_next[3] = {state_reg[3][0], state_reg[3][3], state_reg[3][2], state_reg[3][1]};

                if (round_count == 9) begin
                    next_state = LAST_ROUND_ADD_KEY;
                end else begin
                    next_state = MIX_COLUMNS;
                end
            end

            MIX_COLUMNS: begin
                for (int c = 0; c < 4; c++) begin
                    logic [7:0] col_in[4];
                    logic [7:0] col_out[4];

                    for (int r = 0; r < 4; r++) begin
                        col_in[r] = state_reg[r][c];
                    end

                    col_out[0] = xtime(col_in[0]) ^ (xtime(col_in[1]) ^ col_in[1]) ^ col_in[2] ^ col_in[3];
                    col_out[1] = col_in[0] ^ xtime(col_in[1]) ^ (xtime(col_in[2]) ^ col_in[2]) ^ col_in[3];
                    col_out[2] = col_in[0] ^ col_in[1] ^ xtime(col_in[2]) ^ (xtime(col_in[3]) ^ col_in[3]);
                    col_out[3] = (xtime(col_in[0]) ^ col_in[0]) ^ col_in[1] ^ col_in[2] ^ xtime(col_in[3]);

                    for (int r = 0; r < 4; r++) begin
                        state_next[r][c] = col_out[r];
                    end
                end
                next_state = ADD_KEY;
                round_count_next = round_count + 1;
            end

            LAST_ROUND_ADD_KEY: begin
                for (int r = 0; r < 4; r++) begin
                    for (int c = 0; c < 4; c++) begin
                        state_next[r][c] = state_reg[r][c] ^ round_key[r*32 + c*8 +: 8];
                    end
                end
                next_state = DONE;
            end

            DONE: begin
                busy = 1'b0;
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

    function automatic logic [7:0] xtime(logic [7:0] b);
        return (b[7] ? (b << 1) ^ 8'h1B : (b << 1));
    endfunction

    assign ciphertext = state_reg;
    assign data_valid = data_valid_reg;

endmodule
