`timescale 1ns / 1ps

module aes_sbox (
    input  logic [7:0] sbox_in,
    output logic [7:0] sbox_out
);

    logic [7:0] to_inv;
    logic [7:0] from_inv;
    logic [7:0] aff_in;
    logic [7:0] aff_out;

    assign to_inv[0] = sbox_in[0] ^ sbox_in[4] ^ sbox_in[6];
    assign to_inv[1] = sbox_in[1] ^ sbox_in[5] ^ sbox_in[7];
    assign to_inv[2] = sbox_in[0] ^ sbox_in[2] ^ sbox_in[4] ^ sbox_in[5];
    assign to_inv[3] = sbox_in[1] ^ sbox_in[3] ^ sbox_in[5] ^ sbox_in[6];
    assign to_inv[4] = sbox_in[2] ^ sbox_in[4] ^ sbox_in[7];
    assign to_inv[5] = sbox_in[3] ^ sbox_in[5];
    assign to_inv[6] = sbox_in[6];
    assign to_inv[7] = sbox_in[7];

    gf_inv gf_inverter (
        .a(to_inv),
        .y(from_inv)
    );

    assign aff_in[0] = from_inv[2] ^ from_inv[4] ^ from_inv[5] ^ from_inv[6];
    assign aff_in[1] = from_inv[3] ^ from_inv[5] ^ from_inv[6] ^ from_inv[7];
    assign aff_in[2] = from_inv[0] ^ from_inv[4] ^ from_inv[6];
    assign aff_in[3] = from_inv[1] ^ from_inv[5] ^ from_inv[7];
    assign aff_in[4] = from_inv[0] ^ from_inv[2] ^ from_inv[7];
    assign aff_in[5] = from_inv[1] ^ from_inv[3];
    assign aff_in[6] = from_inv[2] ^ from_inv[6];
    assign aff_in[7] = from_inv[3] ^ from_inv[7];
    assign aff_out[0] = aff_in[0] ^ aff_in[4] ^ aff_in[5] ^ aff_in[6] ^ aff_in[7];
    assign aff_out[1] = aff_in[0] ^ aff_in[1] ^ aff_in[5] ^ aff_in[6] ^ aff_in[7];
    assign aff_out[2] = aff_in[0] ^ aff_in[1] ^ aff_in[2] ^ aff_in[6] ^ aff_in[7];
    assign aff_out[3] = aff_in[0] ^ aff_in[1] ^ aff_in[2] ^ aff_in[3] ^ aff_in[7];
    assign aff_out[4] = aff_in[0] ^ aff_in[1] ^ aff_in[2] ^ aff_in[3] ^ aff_in[4];
    assign aff_out[5] = aff_in[1] ^ aff_in[2] ^ aff_in[3] ^ aff_in[4] ^ aff_in[5];
    assign aff_out[6] = aff_in[2] ^ aff_in[3] ^ aff_in[4] ^ aff_in[5] ^ aff_in[6];
    assign aff_out[7] = aff_in[3] ^ aff_in[4] ^ aff_in[5] ^ aff_in[6] ^ aff_in[7];
    assign sbox_out = aff_out ^ 8'h63;

endmodule

module gf_inv (
    input  logic [7:0] a,
    output logic [7:0] y
);

    logic [3:0] a_h, a_l;
    logic [3:0] s0, s1, m0, m1, p0, p1;
    logic [3:0] d, d_inv;

    assign a_h = a[7:4];
    assign a_l = a[3:0];

    assign s0[0] = a_l[0] ^ a_l[1];
    assign s0[1] = a_l[1];
    assign s0[2] = a_l[2] ^ a_l[3];
    assign s0[3] = a_l[3];
    assign s1[0] = a_h[0] ^ a_h[1];
    assign s1[1] = a_h[1];
    assign s1[2] = a_h[2] ^ a_h[3];
    assign s1[3] = a_h[3];

    assign m0[0] = (a_l[0] & a_h[0]) ^ (a_l[1] & a_h[3]) ^ (a_l[2] & a_h[2]) ^ (a_l[3] & a_h[1]);
    assign m0[1] = (a_l[0] & a_h[1]) ^ (a_l[1] & a_h[0]) ^ (a_l[1] & a_h[3]) ^ (a_l[2] & a_h[2]) ^ (a_l[2] & a_h[3]) ^ (a_l[3] & a_h[1]) ^ (a_l[3] & a_h[2]);
    assign m0[2] = (a_l[0] & a_h[2]) ^ (a_l[1] & a_h[1]) ^ (a_l[2] & a_h[0]) ^ (a_l[2] & a_h[3]) ^ (a_l[3] & a_h[2]);
    assign m0[3] = (a_l[0] & a_h[3]) ^ (a_l[1] & a_h[2]) ^ (a_l[2] & a_h[1]) ^ (a_l[3] & a_h[0]) ^ (a_l[3] & a_h[3]);

    assign m1 = m0 ^ s1;
    assign d = s0 ^ m1;

    assign p0[0] = d[0] ^ d[2];
    assign p0[1] = d[1] ^ d[3];
    assign p0[2] = p0[0] ^ d[1];
    assign p0[3] = p0[1] ^ d[0];
    assign p1[0] = (p0[0] & p0[1]) ^ p0[2];
    assign p1[1] = (p0[0] & p0[3]) ^ p0[2] ^ p0[3];
    assign p1[2] = (p0[2] & p0[3]) ^ p0[0];
    assign p1[3] = (p0[1] & p0[2]) ^ p0[0] ^ p0[1];

    assign d_inv[0] = (p1[0] & d[0]) ^ (p1[1] & d[1]) ^ (p1[2] & d[2]) ^ (p1[3] & d[3]);
    assign d_inv[1] = (p1[0] & d[1]) ^ (p1[1] & d[0]) ^ (p1[1] & d[2]) ^ (p1[2] & d[1]) ^ (p1[2] & d[3]) ^ (p1[3] & d[2]) ^ (p1[3] & d[0]);
    assign d_inv[2] = (p1[0] & d[2]) ^ (p1[1] & d[3]) ^ (p1[2] & d[0]) ^ (p1[2] & d[1]) ^ (p1[3] & d[3]);
    assign d_inv[3] = (p1[0] & d[3]) ^ (p1[1] & d[2]) ^ (p1[2] & d[1]) ^ (p1[3] & d[0]) ^ (p1[3] & d[1]);

    assign y[7:4] = {
        (m0[0] & d_inv[0]) ^ (m0[1] & d_inv[3]) ^ (m0[2] & d_inv[2]) ^ (m0[3] & d_inv[1]),
        (m0[0] & d_inv[1]) ^ (m0[1] & d_inv[0]) ^ (m0[1] & d_inv[3]) ^ (m0[2] & d_inv[2]) ^ (m0[2] & d_inv[3]) ^ (m0[3] & d_inv[1]) ^ (m0[3] & d_inv[2]),
        (m0[0] & d_inv[2]) ^ (m0[1] & d_inv[1]) ^ (m0[2] & d_inv[0]) ^ (m0[2] & d_inv[3]) ^ (m0[3] & d_inv[2]),
        (m0[0] & d_inv[3]) ^ (m0[1] & d_inv[2]) ^ (m0[2] & d_inv[1]) ^ (m0[3] & d_inv[0]) ^ (m0[3] & d_inv[3])
    };
    assign y[3:0] = y[7:4] ^ a_h;

endmodule
