`timescale 1ns/1ps
// aes128_top.v - Verilog-2001 compatible, no wire arrays, no nested constructs

module aes128_top (
    input  wire         clk,
    input  wire         rst,
    input  wire [127:0] plaintext,
    input  wire [127:0] key,
    input  wire         data_valid,
    output reg  [127:0] ciphertext,
    output reg          out_valid
);

    // -----------------------------------------------------------------------
    // Key words: 44 words (kw0..kw43) declared individually
    // Vivado Verilog-2001 does not support wire arrays in generate blocks
    // -----------------------------------------------------------------------
    wire [31:0] kw0,  kw1,  kw2,  kw3;
    wire [31:0] kw4,  kw5,  kw6,  kw7;
    wire [31:0] kw8,  kw9,  kw10, kw11;
    wire [31:0] kw12, kw13, kw14, kw15;
    wire [31:0] kw16, kw17, kw18, kw19;
    wire [31:0] kw20, kw21, kw22, kw23;
    wire [31:0] kw24, kw25, kw26, kw27;
    wire [31:0] kw28, kw29, kw30, kw31;
    wire [31:0] kw32, kw33, kw34, kw35;
    wire [31:0] kw36, kw37, kw38, kw39;
    wire [31:0] kw40, kw41, kw42, kw43;

    // Initial 4 words come directly from the key input
    // -----------------------------------------------------------------------
    // NIST/MBEDTLS ENDIANNESS FIX: Swap input key and plaintext byte order
    // -----------------------------------------------------------------------
  // Initial 4 words come directly from the key input
    assign kw0  = key[127:96];
    assign kw1  = key[ 95:64];
    assign kw2  = key[ 63:32];
    assign kw3  = key[ 31: 0];

    // -----------------------------------------------------------------------
    // SubWord helper wires for each of the 10 key schedule rounds
    // Each round needs: RotWord of previous last word, SubWord, XOR with Rcon
    // -----------------------------------------------------------------------

    // Round 1 - Rcon = 0x01
    wire [7:0] ks1_b0, ks1_b1, ks1_b2, ks1_b3;
    aes_sbox ks1s0 (.in(kw3[23:16]), .out(ks1_b0)); // RotWord: [23:16]
    aes_sbox ks1s1 (.in(kw3[15: 8]), .out(ks1_b1)); // RotWord: [15: 8]
    aes_sbox ks1s2 (.in(kw3[ 7: 0]), .out(ks1_b2)); // RotWord: [ 7: 0]
    aes_sbox ks1s3 (.in(kw3[31:24]), .out(ks1_b3)); // RotWord: [31:24]
    assign kw4  = kw0  ^ {ks1_b0 ^ 8'h01, ks1_b1, ks1_b2, ks1_b3};
    assign kw5  = kw1  ^ kw4;
    assign kw6  = kw2  ^ kw5;
    assign kw7  = kw3  ^ kw6;

    // Round 2 - Rcon = 0x02
    wire [7:0] ks2_b0, ks2_b1, ks2_b2, ks2_b3;
    aes_sbox ks2s0 (.in(kw7[23:16]), .out(ks2_b0));
    aes_sbox ks2s1 (.in(kw7[15: 8]), .out(ks2_b1));
    aes_sbox ks2s2 (.in(kw7[ 7: 0]), .out(ks2_b2));
    aes_sbox ks2s3 (.in(kw7[31:24]), .out(ks2_b3));
    assign kw8  = kw4  ^ {ks2_b0 ^ 8'h02, ks2_b1, ks2_b2, ks2_b3};
    assign kw9  = kw5  ^ kw8;
    assign kw10 = kw6  ^ kw9;
    assign kw11 = kw7  ^ kw10;

    // Round 3 - Rcon = 0x04
    wire [7:0] ks3_b0, ks3_b1, ks3_b2, ks3_b3;
    aes_sbox ks3s0 (.in(kw11[23:16]), .out(ks3_b0));
    aes_sbox ks3s1 (.in(kw11[15: 8]), .out(ks3_b1));
    aes_sbox ks3s2 (.in(kw11[ 7: 0]), .out(ks3_b2));
    aes_sbox ks3s3 (.in(kw11[31:24]), .out(ks3_b3));
    assign kw12 = kw8  ^ {ks3_b0 ^ 8'h04, ks3_b1, ks3_b2, ks3_b3};
    assign kw13 = kw9  ^ kw12;
    assign kw14 = kw10 ^ kw13;
    assign kw15 = kw11 ^ kw14;

    // Round 4 - Rcon = 0x08
    wire [7:0] ks4_b0, ks4_b1, ks4_b2, ks4_b3;
    aes_sbox ks4s0 (.in(kw15[23:16]), .out(ks4_b0));
    aes_sbox ks4s1 (.in(kw15[15: 8]), .out(ks4_b1));
    aes_sbox ks4s2 (.in(kw15[ 7: 0]), .out(ks4_b2));
    aes_sbox ks4s3 (.in(kw15[31:24]), .out(ks4_b3));
    assign kw16 = kw12 ^ {ks4_b0 ^ 8'h08, ks4_b1, ks4_b2, ks4_b3};
    assign kw17 = kw13 ^ kw16;
    assign kw18 = kw14 ^ kw17;
    assign kw19 = kw15 ^ kw18;

    // Round 5 - Rcon = 0x10
    wire [7:0] ks5_b0, ks5_b1, ks5_b2, ks5_b3;
    aes_sbox ks5s0 (.in(kw19[23:16]), .out(ks5_b0));
    aes_sbox ks5s1 (.in(kw19[15: 8]), .out(ks5_b1));
    aes_sbox ks5s2 (.in(kw19[ 7: 0]), .out(ks5_b2));
    aes_sbox ks5s3 (.in(kw19[31:24]), .out(ks5_b3));
    assign kw20 = kw16 ^ {ks5_b0 ^ 8'h10, ks5_b1, ks5_b2, ks5_b3};
    assign kw21 = kw17 ^ kw20;
    assign kw22 = kw18 ^ kw21;
    assign kw23 = kw19 ^ kw22;

    // Round 6 - Rcon = 0x20
    wire [7:0] ks6_b0, ks6_b1, ks6_b2, ks6_b3;
    aes_sbox ks6s0 (.in(kw23[23:16]), .out(ks6_b0));
    aes_sbox ks6s1 (.in(kw23[15: 8]), .out(ks6_b1));
    aes_sbox ks6s2 (.in(kw23[ 7: 0]), .out(ks6_b2));
    aes_sbox ks6s3 (.in(kw23[31:24]), .out(ks6_b3));
    assign kw24 = kw20 ^ {ks6_b0 ^ 8'h20, ks6_b1, ks6_b2, ks6_b3};
    assign kw25 = kw21 ^ kw24;
    assign kw26 = kw22 ^ kw25;
    assign kw27 = kw23 ^ kw26;

    // Round 7 - Rcon = 0x40
    wire [7:0] ks7_b0, ks7_b1, ks7_b2, ks7_b3;
    aes_sbox ks7s0 (.in(kw27[23:16]), .out(ks7_b0));
    aes_sbox ks7s1 (.in(kw27[15: 8]), .out(ks7_b1));
    aes_sbox ks7s2 (.in(kw27[ 7: 0]), .out(ks7_b2));
    aes_sbox ks7s3 (.in(kw27[31:24]), .out(ks7_b3));
    assign kw28 = kw24 ^ {ks7_b0 ^ 8'h40, ks7_b1, ks7_b2, ks7_b3};
    assign kw29 = kw25 ^ kw28;
    assign kw30 = kw26 ^ kw29;
    assign kw31 = kw27 ^ kw30;

    // Round 8 - Rcon = 0x80
    wire [7:0] ks8_b0, ks8_b1, ks8_b2, ks8_b3;
    aes_sbox ks8s0 (.in(kw31[23:16]), .out(ks8_b0));
    aes_sbox ks8s1 (.in(kw31[15: 8]), .out(ks8_b1));
    aes_sbox ks8s2 (.in(kw31[ 7: 0]), .out(ks8_b2));
    aes_sbox ks8s3 (.in(kw31[31:24]), .out(ks8_b3));
    assign kw32 = kw28 ^ {ks8_b0 ^ 8'h80, ks8_b1, ks8_b2, ks8_b3};
    assign kw33 = kw29 ^ kw32;
    assign kw34 = kw30 ^ kw33;
    assign kw35 = kw31 ^ kw34;

    // Round 9 - Rcon = 0x1b
    wire [7:0] ks9_b0, ks9_b1, ks9_b2, ks9_b3;
    aes_sbox ks9s0 (.in(kw35[23:16]), .out(ks9_b0));
    aes_sbox ks9s1 (.in(kw35[15: 8]), .out(ks9_b1));
    aes_sbox ks9s2 (.in(kw35[ 7: 0]), .out(ks9_b2));
    aes_sbox ks9s3 (.in(kw35[31:24]), .out(ks9_b3));
    assign kw36 = kw32 ^ {ks9_b0 ^ 8'h1b, ks9_b1, ks9_b2, ks9_b3};
    assign kw37 = kw33 ^ kw36;
    assign kw38 = kw34 ^ kw37;
    assign kw39 = kw35 ^ kw38;

    // Round 10 - Rcon = 0x36
    wire [7:0] ks10_b0, ks10_b1, ks10_b2, ks10_b3;
    aes_sbox ks10s0 (.in(kw39[23:16]), .out(ks10_b0));
    aes_sbox ks10s1 (.in(kw39[15: 8]), .out(ks10_b1));
    aes_sbox ks10s2 (.in(kw39[ 7: 0]), .out(ks10_b2));
    aes_sbox ks10s3 (.in(kw39[31:24]), .out(ks10_b3));
    assign kw40 = kw36 ^ {ks10_b0 ^ 8'h36, ks10_b1, ks10_b2, ks10_b3};
    assign kw41 = kw37 ^ kw40;
    assign kw42 = kw38 ^ kw41;
    assign kw43 = kw39 ^ kw42;

    // -----------------------------------------------------------------------
    // Round keys assembled from word pairs
    // -----------------------------------------------------------------------
    wire [127:0] rk0  = {kw0,  kw1,  kw2,  kw3 };
    wire [127:0] rk1  = {kw4,  kw5,  kw6,  kw7 };
    wire [127:0] rk2  = {kw8,  kw9,  kw10, kw11};
    wire [127:0] rk3  = {kw12, kw13, kw14, kw15};
    wire [127:0] rk4  = {kw16, kw17, kw18, kw19};
    wire [127:0] rk5  = {kw20, kw21, kw22, kw23};
    wire [127:0] rk6  = {kw24, kw25, kw26, kw27};
    wire [127:0] rk7  = {kw28, kw29, kw30, kw31};
    wire [127:0] rk8  = {kw32, kw33, kw34, kw35};
    wire [127:0] rk9  = {kw36, kw37, kw38, kw39};
    wire [127:0] rk10 = {kw40, kw41, kw42, kw43};

    // -----------------------------------------------------------------------
    // Pipeline: 11 state registers + 11 valid registers
    // Declared as flat reg arrays - supported in Verilog-2001
    // -----------------------------------------------------------------------
    reg [127:0] ps0,  ps1,  ps2,  ps3,  ps4,
                ps5,  ps6,  ps7,  ps8,  ps9,  ps10;
    reg         pv0,  pv1,  pv2,  pv3,  pv4,
                pv5,  pv6,  pv7,  pv8,  pv9,  pv10;

    wire [127:0] ro0, ro1, ro2, ro3, ro4,
                 ro5, ro6, ro7, ro8, ro9;

    // Stage 0: initial AddRoundKey (plaintext XOR rk0)
    always @(posedge clk or posedge rst) begin
        if (rst) begin ps0 <= 128'h0; pv0 <= 1'b0; end
        else     begin ps0 <= plaintext ^ rk0; pv0 <= data_valid; end
    end

    // Rounds 1-10: each aes_round is combinational, output registered
    aes_round u_r0  (.state_in(ps0),  .round_key(rk1),  .last_round(1'b0), .state_out(ro0));
    aes_round u_r1  (.state_in(ps1),  .round_key(rk2),  .last_round(1'b0), .state_out(ro1));
    aes_round u_r2  (.state_in(ps2),  .round_key(rk3),  .last_round(1'b0), .state_out(ro2));
    aes_round u_r3  (.state_in(ps3),  .round_key(rk4),  .last_round(1'b0), .state_out(ro3));
    aes_round u_r4  (.state_in(ps4),  .round_key(rk5),  .last_round(1'b0), .state_out(ro4));
    aes_round u_r5  (.state_in(ps5),  .round_key(rk6),  .last_round(1'b0), .state_out(ro5));
    aes_round u_r6  (.state_in(ps6),  .round_key(rk7),  .last_round(1'b0), .state_out(ro6));
    aes_round u_r7  (.state_in(ps7),  .round_key(rk8),  .last_round(1'b0), .state_out(ro7));
    aes_round u_r8  (.state_in(ps8),  .round_key(rk9),  .last_round(1'b0), .state_out(ro8));
    aes_round u_r9  (.state_in(ps9),  .round_key(rk10), .last_round(1'b1), .state_out(ro9));

    always @(posedge clk or posedge rst) begin
        if (rst) begin ps1  <= 128'h0; pv1  <= 1'b0; end
        else     begin ps1  <= ro0;    pv1  <= pv0;  end
    end
    always @(posedge clk or posedge rst) begin
        if (rst) begin ps2  <= 128'h0; pv2  <= 1'b0; end
        else     begin ps2  <= ro1;    pv2  <= pv1;  end
    end
    always @(posedge clk or posedge rst) begin
        if (rst) begin ps3  <= 128'h0; pv3  <= 1'b0; end
        else     begin ps3  <= ro2;    pv3  <= pv2;  end
    end
    always @(posedge clk or posedge rst) begin
        if (rst) begin ps4  <= 128'h0; pv4  <= 1'b0; end
        else     begin ps4  <= ro3;    pv4  <= pv3;  end
    end
    always @(posedge clk or posedge rst) begin
        if (rst) begin ps5  <= 128'h0; pv5  <= 1'b0; end
        else     begin ps5  <= ro4;    pv5  <= pv4;  end
    end
    always @(posedge clk or posedge rst) begin
        if (rst) begin ps6  <= 128'h0; pv6  <= 1'b0; end
        else     begin ps6  <= ro5;    pv6  <= pv5;  end
    end
    always @(posedge clk or posedge rst) begin
        if (rst) begin ps7  <= 128'h0; pv7  <= 1'b0; end
        else     begin ps7  <= ro6;    pv7  <= pv6;  end
    end
    always @(posedge clk or posedge rst) begin
        if (rst) begin ps8  <= 128'h0; pv8  <= 1'b0; end
        else     begin ps8  <= ro7;    pv8  <= pv7;  end
    end
    always @(posedge clk or posedge rst) begin
        if (rst) begin ps9  <= 128'h0; pv9  <= 1'b0; end
        else     begin ps9  <= ro8;    pv9  <= pv8;  end
    end
    always @(posedge clk or posedge rst) begin
        if (rst) begin ps10 <= 128'h0; pv10 <= 1'b0; end
        else     begin ps10 <= ro9;    pv10 <= pv9;  end
    end

    // -----------------------------------------------------------------------
    // Output: ps10 holds the final ciphertext, pv10 is out_valid
    // Total pipeline latency: 11 clock cycles after data_valid
    // -----------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ciphertext <= 128'h0;
            out_valid  <= 1'b0;
        end else begin
            ciphertext <= ps10;
            out_valid  <= pv10;
        end
    end

endmodule