`timescale 1ns / 1ps

module aes_key_expand (
    input  logic         clk,
    input  logic         aresetn,
    input  logic         key_init_start,
    input  logic [127:0] key_in,
    input  logic [3:0]   round,
    output logic [127:0] round_key,
    output logic         key_ready
);

    logic [127:0] key_reg;
    logic [127:0] next_key;
    logic         key_ready_reg;

    localparam [9:0][7:0] Rcon = {
        8'h01, 8'h02, 8'h04, 8'h08, 8'h10, 8'h20, 8'h40, 8'h80, 8'h1b, 8'h36
    };

    logic [7:0]  w0_sub, w1_sub, w2_sub, w3_sub;
    logic [31:0] w_new;

    // Use registered key bits as S-box input to avoid combinational feedback.
    aes_sbox sbox0 (.sbox_in(key_reg[23:16]), .sbox_out(w0_sub));
    aes_sbox sbox1 (.sbox_in(key_reg[15:8]),  .sbox_out(w1_sub));
    aes_sbox sbox2 (.sbox_in(key_reg[7:0]),   .sbox_out(w2_sub));
    aes_sbox sbox3 (.sbox_in(key_reg[31:24]), .sbox_out(w3_sub));

    always_comb begin
        next_key = key_reg;

        if ((round > 0) && (round < 11)) begin
            w_new[31:24] = w0_sub ^ Rcon[round - 1] ^ key_reg[127:120];
            w_new[23:16] = w1_sub ^ key_reg[119:112];
            w_new[15:8]  = w2_sub ^ key_reg[111:104];
            w_new[7:0]   = w3_sub ^ key_reg[103:96];

            next_key[127:96] = w_new;
            next_key[95:64]  = key_reg[95:64] ^ w_new;
            next_key[63:32]  = key_reg[63:32] ^ next_key[95:64];
            next_key[31:0]   = key_reg[31:0] ^ next_key[63:32];
        end
    end

    always_ff @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            key_reg <= 128'b0;
            key_ready_reg <= 1'b0;
        end else if (key_init_start) begin
            key_reg <= key_in;
            key_ready_reg <= 1'b1;
        end else if (round > 0 && round < 11) begin
            key_reg <= next_key;
        end
    end

    assign round_key = (round == 0) ? key_in : key_reg;
    assign key_ready = key_ready_reg;

endmodule
