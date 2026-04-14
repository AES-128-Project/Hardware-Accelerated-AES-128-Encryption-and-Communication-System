`timescale 1ns/1ps
// One AES round: SubBytes → ShiftRows → MixColumns → AddRoundKey
// Fully combinational (registered at top level for pipeline)
// last_round=1: skip MixColumns (AES spec requirement for round 10)

module aes_round (
    input  wire [127:0] state_in,
    input  wire [127:0] round_key,
    input  wire         last_round,
    output wire [127:0] state_out
);

    // -----------------------------------------------------------------------
    // SubBytes: apply S-Box to all 16 bytes
    // -----------------------------------------------------------------------
    wire [127:0] after_sub;
    genvar gi;
    generate
        for (gi = 0; gi < 16; gi = gi + 1) begin : g_sub
            aes_sbox u_sb (
                .in  (state_in[127 - gi*8 -: 8]),
                .out (after_sub[127 - gi*8 -: 8])
            );
        end
    endgenerate

    // -----------------------------------------------------------------------
    // ShiftRows: byte rotation per row
    // AES state is column-major: bytes 0,4,8,12 = col0; 1,5,9,13 = col1 etc.
    // Row 0: no shift
    // Row 1: left-rotate 1
    // Row 2: left-rotate 2
    // Row 3: left-rotate 3
    // Byte index in 128-bit vector: byte n occupies bits [127-8n : 120-8n]
    // -----------------------------------------------------------------------
    // Extract bytes from after_sub (row-major naming for clarity)
    wire [7:0] s[0:15];
    genvar gj;
    generate
        for (gj = 0; gj < 16; gj = gj + 1) begin : g_extract
            assign s[gj] = after_sub[127 - gj*8 -: 8];
        end
    endgenerate

    // AES state layout (column-major, 4×4):
    // s[0] s[4] s[8]  s[12]   row 0
    // s[1] s[5] s[9]  s[13]   row 1  → shift left 1: s[5] s[9] s[13] s[1]
    // s[2] s[6] s[10] s[14]   row 2  → shift left 2: s[10] s[14] s[2] s[6]
    // s[3] s[7] s[11] s[15]   row 3  → shift left 3: s[15] s[3] s[7] s[11]

    wire [127:0] after_shift;
    assign after_shift = {
        s[ 0], s[ 5], s[10], s[15],   // col 0
        s[ 4], s[ 9], s[14], s[ 3],   // col 1
        s[ 8], s[13], s[ 2], s[ 7],   // col 2
        s[12], s[ 1], s[ 6], s[11]    // col 3
    };
    // Re-expressed as column-major output for MixColumns:
    // col0: s[0], s[5], s[10], s[15]
    // col1: s[4], s[9], s[14], s[3]
    // col2: s[8], s[13], s[2], s[7]
    // col3: s[12], s[1], s[6], s[11]

    // -----------------------------------------------------------------------
    // MixColumns: apply to each of 4 columns
    // -----------------------------------------------------------------------
    wire [31:0] mc_col[0:3];
    wire [127:0] after_mix;

    genvar gk;
    generate
        for (gk = 0; gk < 4; gk = gk + 1) begin : g_mix
            aes_mixcols u_mc (
                .col_in  (after_shift[127 - gk*32 -: 32]),
                .col_out (mc_col[gk])
            );
        end
    endgenerate

    assign after_mix = last_round ? after_shift :
                       {mc_col[0], mc_col[1], mc_col[2], mc_col[3]};

    // -----------------------------------------------------------------------
    // AddRoundKey
    // -----------------------------------------------------------------------
    assign state_out = after_mix ^ round_key;

endmodule