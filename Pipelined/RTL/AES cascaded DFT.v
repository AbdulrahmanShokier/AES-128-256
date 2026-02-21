module AES_hardware_test_top #(parameter BLOCK_LENGTH = 128)
(
    input  clk,           // 100 MHz on-board clock
    input  btn_rst,       // Push button for Reset (BTND)
    input  btn_start,     // Push button for Start (BTNC)
    
    output reg led_success, // LD0: Perfect Match
    output reg led_error,   // LD1: Mismatch occurred
    output reg led_done,    // LD2: Processing Finished
    
    output led_feeding,     // LD3: ON when feeding data
    output led_wait_key,    // LD4: ON when doing Key Expansion
    output led_idle,        // LD5: ON when waiting for start button
    output led_heartbeat    // LD7: Blinking proves clock is alive
);

    // -------------------------------------------------
    // Invert the physical button to match active-low reset
    // Unpressed (0) becomes 1 (Run). Pressed (1) becomes 0 (Reset).
    // -------------------------------------------------
    wire rst_n = ~btn_rst; 

    // -------------------------------------------------
    // Clock Divider 
    // -------------------------------------------------
    reg [25:0] clk_cnt;
    always @(posedge clk) begin
        clk_cnt <= clk_cnt + 1;
    end
    
    wire slow_clk = clk_cnt[4];         // ~3.1 MHz for AES Logic
    assign led_heartbeat = clk_cnt[25]; // ~1.5 Hz for Heartbeat LED

    // -------------------------------------------------
    // Start Button Synchronizer (Prevents glitches)
    // -------------------------------------------------
    reg btn_sync_0, btn_sync_1;
    always @(posedge slow_clk) begin
        if (!rst_n) begin
            btn_sync_0 <= 1'b0;
            btn_sync_1 <= 1'b0;
        end else begin
            btn_sync_0 <= btn_start;
            btn_sync_1 <= btn_sync_0; // Clean, synchronized start signal
        end
    end

    // -------------------------------------------------
    // Test Vectors
    // -------------------------------------------------
    function [127:0] get_vector;
        input [3:0] index;
        begin
            case (index)
                4'd0:  get_vector = 128'h00112233445566778899AABBCCDDEEFF;
                4'd1:  get_vector = 128'h00112233445566000099AABBCCDDEEFF;
                4'd2:  get_vector = 128'h66542233445566000099AABBCCDDEEFF;
                4'd3:  get_vector = 128'h00000000000000000000000000000000;
                4'd4:  get_vector = 128'h11111111111111111111111111111111;
                4'd5:  get_vector = 128'h10101010101010101010101010101010;
                4'd6:  get_vector = 128'h01010101010101010101010101010101;
                4'd7:  get_vector = 128'h05050505050505050505050505050505;
                4'd8:  get_vector = 128'hffffffffffffffffffffffffffffffff;
                4'd9:  get_vector = 128'h33333333333333333333333333333333;
                4'd10: get_vector = 128'hcccccccccccccccccccccccccccccccc;
                default: get_vector = 128'h0;
            endcase
        end
    endfunction

    // -------------------------------------------------
    // Internal Signals
    // -------------------------------------------------
    wire [127:0] key = 128'h000102030405060708090A0B0C0D0E0F;
    reg  [127:0] plaintext_in;
    reg          enable, fsm_en;
    wire [127:0] internal_ciphertext, plaintext_out;
    wire         enc_valid, dec_valid;

    // ==========================================
    // AES Cascade Instantiation
    // ==========================================
    AES_enc #(.BLOCK_LENGTH(BLOCK_LENGTH)) encoder_inst (
        .clk(slow_clk), .rst(rst_n),
        .IN(plaintext_in), .KEY(key),
        .enable(enable), .fsm_en(fsm_en),
        .OUT(internal_ciphertext), .valid_out(enc_valid)
    );

    AES_dec #(.BLOCK_LENGTH(BLOCK_LENGTH)) decoder_inst (
        .clk(slow_clk), .rst(rst_n),
        .IN(internal_ciphertext), .KEY(key),
        .enable(enc_valid), .fsm_en(fsm_en),
        .OUT(plaintext_out), .valid_out(dec_valid)
    );

    // ==========================================
    // Input Driver FSM
    // ==========================================
    reg [2:0] state;
    reg [3:0] in_cnt;
    reg [4:0] wait_cnt;

    localparam IDLE = 0, KEY_GEN = 1, WAIT_KEY = 2, FEED = 3, HALT = 4;

    assign led_idle     = (state == IDLE);
    assign led_wait_key = (state == WAIT_KEY || state == KEY_GEN);
    assign led_feeding  = (state == FEED);

    always @(posedge slow_clk) begin
        if (!rst_n) begin
            state <= IDLE;
            in_cnt <= 0;
            wait_cnt <= 0;
            enable <= 0;
            fsm_en <= 0;
            plaintext_in <= 0;
        end else begin
            case (state)
                IDLE: begin
                    // Wait here until the synchronized start button is pressed
                    if (btn_sync_1) begin
                        state <= KEY_GEN;
                    end
                end
                
                KEY_GEN: begin
                    fsm_en <= 1; 
                    state <= WAIT_KEY;
                    wait_cnt <= 0;
                end
                
                WAIT_KEY: begin
                    fsm_en <= 0;
                    if (wait_cnt == 11) state <= FEED;
                    else wait_cnt <= wait_cnt + 1;
                end
                
                FEED: begin
                    if (in_cnt <= 10) begin
                        enable <= 1;
                        plaintext_in <= get_vector(in_cnt);
                        in_cnt <= in_cnt + 1;
                    end else begin
                        enable <= 0;       
                        plaintext_in <= 0;
                        state <= HALT;
                    end
                end
                
                HALT: enable <= 0;
            endcase
        end
    end

    // ==========================================
    // Output Checker Logic
    // ==========================================
    reg [3:0] out_cnt;
    reg       error_flag;

    always @(posedge slow_clk) begin
        if (!rst_n) begin
            out_cnt <= 0;
            error_flag <= 0;
            led_success <= 0;
            led_error <= 0;
            led_done <= 0;
        end else begin
            if (dec_valid && !led_done) begin
                if (plaintext_out != get_vector(out_cnt)) begin
                    error_flag <= 1;
                    led_error <= 1; 
                end
                
                if (out_cnt == 10) begin
                    led_done <= 1; 
                    if (!error_flag && (plaintext_out == get_vector(10))) begin
                        led_success <= 1; 
                    end
                end else begin
                    out_cnt <= out_cnt + 1;
                end
            end
        end
    end
endmodule