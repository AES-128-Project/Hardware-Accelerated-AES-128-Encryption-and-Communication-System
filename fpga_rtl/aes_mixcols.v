`timescale 1ns/1ps
// AES MixColumns: operates on one 32-bit column
// Uses xtime (multiply by 2 in GF(2^8)) to form the matrix product

module aes_mixcols (
    input  wire [31:0] col_in,   // {b0, b1, b2, b3}
    output wire [31:0] col_out
);
    wire [7:0] b0 = col_in[31:24];
    wire [7:0] b1 = col_in[23:16];
    wire [7:0] b2 = col_in[15: 8];
    wire [7:0] b3 = col_in[ 7: 0];

    // xtime: multiply by 2 in GF(2^8) with reduction poly 0x1B
    function [7:0] xtime;
        input [7:0] x;
        xtime = {x[6:0], 1'b0} ^ (x[7] ? 8'h1b : 8'h00);
    endfunction

    // AES MixColumns matrix multiplication (fixed-point GF coefficients)
    // [2 3 1 1]   [b0]
    // [1 2 3 1] × [b1]
    // [1 1 2 3]   [b2]
    // [3 1 1 2]   [b3]
    wire [7:0] x0 = xtime(b0);
    wire [7:0] x1 = xtime(b1);
    wire [7:0] x2 = xtime(b2);
    wire [7:0] x3 = xtime(b3);

    assign col_out[31:24] = x0 ^ (b1 ^ x1) ^ b2 ^ b3;   // 2*b0 ^ 3*b1 ^ b2 ^ b3
    assign col_out[23:16] = b0 ^ x1 ^ (b2 ^ x2) ^ b3;   // b0 ^ 2*b1 ^ 3*b2 ^ b3
    assign col_out[15: 8] = b0 ^ b1 ^ x2 ^ (b3 ^ x3);   // b0 ^ b1 ^ 2*b2 ^ 3*b3
    assign col_out[ 7: 0] = (b0 ^ x0) ^ b1 ^ b2 ^ x3;   // 3*b0 ^ b1 ^ b2 ^ 2*b3

endmodule