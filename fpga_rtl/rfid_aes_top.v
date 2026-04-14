`timescale 1ns / 1ps

module rfid_aes_top (
    input  wire clk,        
    input  wire rst_btn,    
    input  wire rx_esp1,    
    output wire tx_esp2,
    output wire [3:0] led   
);

    localparam SYS_CLK_FREQ = 100_000_000; 
    localparam BAUD_RATE    = 115_200;

    wire [7:0] rx_byte;
    wire       rx_valid;

    // --- State Machine for 0xAA Header Sync ---
    localparam STATE_WAIT_SYNC = 1'b0;
    localparam STATE_READ_UID  = 1'b1;
    reg        rx_state;

    reg [31:0]  rfid_data_reg;
    reg [1:0]   byte_cnt;
    reg         start_aes;
    reg [127:0] aes_plaintext;

    wire [127:0] aes_ciphertext;
    wire         aes_out_valid;
    wire         tx_busy;

    // AES Key (Must match receiver)
    wire [127:0] aes_key = 128'h2b7e151628aed2a6abf7158809cf4f3c;

    // --- DIAGNOSTIC TOGGLE REGISTERS ---
    reg rx_toggle;
    reg aes_in_toggle;
    reg aes_out_toggle;

    always @(posedge clk or posedge rst_btn) begin
        if (rst_btn) begin
            rx_toggle      <= 1'b0;
            aes_in_toggle  <= 1'b0;
            aes_out_toggle <= 1'b0;
        end else begin
            if (rx_valid)      rx_toggle      <= ~rx_toggle;
            if (start_aes)     aes_in_toggle  <= ~aes_in_toggle;
            if (aes_out_valid) aes_out_toggle <= ~aes_out_toggle;
        end
    end

    assign led[0] = rx_toggle;       // Toggles on any incoming UART byte
    assign led[1] = aes_in_toggle;   // Toggles when a valid 4-byte UID is sent to AES
    assign led[2] = aes_out_toggle;  // Toggles when AES finishes encryption
    assign led[3] = tx_busy;         // ON while sending 16 bytes to Transmitter ESP32

    // 1. UART RX
    uart_rx #(
        .CLK_FREQ(SYS_CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_uart_rx (
        .clk       (clk),
        .rst       (rst_btn),
        .rx        (rx_esp1),
        .data_out  (rx_byte),
        .data_valid(rx_valid)
    );

    // 2. Synchronized Accumulator (Looking for 0xAA)
    always @(posedge clk or posedge rst_btn) begin
        if (rst_btn) begin
            rfid_data_reg <= 32'h0;
            byte_cnt      <= 2'd0;
            start_aes     <= 1'b0;
            aes_plaintext <= 128'h0;
            rx_state      <= STATE_WAIT_SYNC;
        end else begin
            start_aes <= 1'b0; // Default off, pulses for 1 clock cycle

            if (rx_valid) begin
                if (rx_state == STATE_WAIT_SYNC) begin
                    // Wait until the magic header arrives
                    if (rx_byte == 8'hAA) begin
                        byte_cnt <= 2'd0;
                        rx_state <= STATE_READ_UID;
                    end
                end else begin 
                    // STATE_READ_UID: Shift in exactly 4 bytes
                    rfid_data_reg <= {rfid_data_reg[23:0], rx_byte};

                    if (byte_cnt == 2'd3) begin
                        // 4 bytes accumulated. Pad with zeros to make 128 bits.
                        aes_plaintext <= {96'h0, rfid_data_reg[23:0], rx_byte};
                        start_aes     <= 1'b1;
                        rx_state      <= STATE_WAIT_SYNC; // Go back to waiting for 0xAA
                    end else begin
                        byte_cnt <= byte_cnt + 1;
                    end
                end
            end
        end
    end

    // 3. AES Encryption
    aes128_top u_aes (
        .clk        (clk),
        .rst        (rst_btn),
        .plaintext  (aes_plaintext),
        .key        (aes_key),
        .data_valid (start_aes),
        .ciphertext (aes_ciphertext),
        .out_valid  (aes_out_valid)
    );

    // 4. UART TX to ESP32 
    uart_tx_128 #(
        .CLK_FREQ  (SYS_CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) u_uart_tx (
        .clk     (clk),
        .rst     (rst_btn),
        .data_in (aes_ciphertext),
        .send    (aes_out_valid),
        .tx      (tx_esp2),
        .busy    (tx_busy)
    );

endmodule
