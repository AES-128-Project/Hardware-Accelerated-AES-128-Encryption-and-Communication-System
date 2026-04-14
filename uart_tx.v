`timescale 1ns/1ps

module uart_tx_128 #(
    parameter CLK_FREQ  = 100_000_000, // Updated default to Basys3 clock
    parameter BAUD_RATE = 115_200
)(
    input  wire         clk,
    input  wire         rst,
    input  wire [127:0] data_in,
    input  wire         send,
    output reg          tx,
    output wire         busy
);
    localparam BAUD_DIV = CLK_FREQ / BAUD_RATE; // 868 at 100 MHz

    localparam [2:0]
        IDLE      = 3'd0,
        LOAD      = 3'd1,
        START_BIT = 3'd2,
        DATA_BITS = 3'd3,
        STOP_BIT  = 3'd4,
        NEXT_BYTE = 3'd5;

    reg [2:0]   state;
    reg [127:0] shift_reg;
    reg [3:0]   byte_idx;
    reg [7:0]   current_byte;
    reg [2:0]   bit_idx;
    
    // --- THE FIX: Increased from 9 bits to 16 bits to prevent overflow! ---
    reg [15:0]  baud_cnt; 

    assign busy = (state != IDLE);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state        <= IDLE;
            tx           <= 1'b1;
            shift_reg    <= 128'h0;
            byte_idx     <= 4'd0;
            current_byte <= 8'h0;     
            baud_cnt     <= 16'd0;   // Match width
            bit_idx      <= 3'd0;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1'b1;
                    if (send) begin
                        shift_reg <= data_in;
                        byte_idx  <= 4'd0;
                        state     <= LOAD;
                    end
                end

                LOAD: begin
                    current_byte <= shift_reg[127:120]; // MSB byte first
                    shift_reg    <= {shift_reg[119:0], 8'h00};
                    baud_cnt     <= 16'd0;
                    bit_idx      <= 3'd0;
                    state        <= START_BIT;
                end

                START_BIT: begin
                    tx <= 1'b0;
                    if (baud_cnt == BAUD_DIV - 1) begin
                        baud_cnt <= 16'd0;
                        state    <= DATA_BITS;
                    end else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end

                DATA_BITS: begin
                    tx <= current_byte[bit_idx];
                    if (baud_cnt == BAUD_DIV - 1) begin
                        baud_cnt <= 16'd0;
                        if (bit_idx == 3'd7) begin
                            state <= STOP_BIT;
                        end else begin
                            bit_idx <= bit_idx + 1;
                        end
                    end else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end

                STOP_BIT: begin
                    tx <= 1'b1;
                    if (baud_cnt == BAUD_DIV - 1) begin
                        baud_cnt <= 16'd0;
                        state    <= NEXT_BYTE;
                    end else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end

                NEXT_BYTE: begin
                    if (byte_idx == 4'd15) begin
                        state <= IDLE;
                    end else begin
                        byte_idx <= byte_idx + 1;
                        state    <= LOAD;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule