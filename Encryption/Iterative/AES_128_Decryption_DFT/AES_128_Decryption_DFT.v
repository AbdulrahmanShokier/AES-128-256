/*
 * Module: AES_DFT_Decrypt
 * Description:
 * This is the test harness adapted for AES DECRYPTION.
 * It instantiates "Top_Module" (the decryption core).
 *
 * 1. Set switches 'sw' to select a Test Case (Ciphertext, Key, Expected Plaintext).
 * 2. Pulse 'rst_n' (active-low) to reset and start the test.
 * 3. The FSM runs the core once.
 * 4. Green LED (led_success) lights up if Decrypted Plaintext == Expected Plaintext.
 */
module AES_DFT_Decrypt (
    input wire clk,       // 100MHz clock from board
    input wire rst_n,     // Reset button (active-low)
    input wire [2:0] sw,  // 3 switches to select test vector
    
    output reg led_success, // LED<0>
    output reg led_fail     // LED<7>
);
    // --- Internal Registers and Wires ---
    // NOTE: For decryption:
    // selected_pt  -> becomes the EXPECTED result (Plaintext)
    // selected_ct  -> becomes the INPUT (Ciphertext)
    reg [127:0] selected_ct;  
    reg [127:0] selected_key;
    reg [127:0] expected_pt; 

    // --- Wires to connect to the Decryption Core ---
    wire [127:0] actual_pt_from_aes; // Output from decryption
    wire         aes_done;           // valid_out
    
    reg          aes_start;          // valid_in
    reg          core_rst;           // Internal reset (active-low for your core)

    // --- State machine ---
    reg [2:0] state;
    localparam STATE_IDLE       = 3'b000;
    localparam STATE_START_AES  = 3'b001;
    localparam STATE_WAIT_AES   = 3'b010;
    localparam STATE_COMPARE    = 3'b011;
    localparam STATE_DONE_LATCH = 3'b100;

    //--------------------------------------------------------------------------
    // 1. Test Vector Storage (ROMs)
    //    These are the SAME vectors as encryption, but swapped:
    //    Input = Ciphertext, Output = Plaintext
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        case (sw)
             // Test Case 0: Appendix B
            3'b000: begin
                selected_ct   <= 128'h3925841d02dc09fbdc118597196a0b32; // Ciphertext
                selected_key  <= 128'h2b7e151628aed2a6abf7158809cf4f3c;
                expected_pt   <= 128'h3243f6a8885a308d313198a2e0370734; // Plaintext
            end
            
            // Test Case 1: Appendix C.1
            3'b001: begin
                selected_ct   <= 128'h69c4e0d86a7b0430d8cdb78070b4c55a;
                selected_key  <= 128'h000102030405060708090a0b0c0d0e0f;
                expected_pt   <= 128'h00112233445566778899aabbccddeeff;
            end
            
            // Test Case 2
            3'b010: begin
                selected_ct   <= 128'h3ad77bb40d7a3660a89ecaf32466ef97;
                selected_key  <= 128'h2b7e151628aed2a6abf7158809cf4f3c;
                expected_pt   <= 128'h6bc1bee22e409f96e93d7e117393172a;
            end

            3'b011: begin
                selected_ct   <= 128'hf5d3d58503b969de785895a96fdbaaf0; // Corrected
                selected_key  <= 128'h2b7e151628aed2a6abf7158809cf4f3c;
                expected_pt   <= 128'hfb7cb6b75d2c68cfd06645a8fda84a21; // Corrected
            end
            
            // Test Case 4
            3'b100: begin
                selected_ct   <= 128'h66e94bd4ef8a2c3b884cfa59ca342b2e;
                selected_key  <= 128'h00000000000000000000000000000000;
                expected_pt   <= 128'h00000000000000000000000000000000;
            end
            
            // Test Case 5
            3'b101: begin
                selected_ct   <= 128'hc8a331ff8edd3db175e1545dbefb760b; // Fixed per your request
                selected_key  <= 128'h00000000000000000000000000000000;
                expected_pt   <= 128'h00112233445566778899aabbccddeeff;
            end

            // Test Case 6
            3'b110: begin
                selected_ct   <= 128'hbcbf217cb280cf30b2517052193ab979; // Fixed per your request
                selected_key  <= 128'hffffffffffffffffffffffffffffffff;
                expected_pt   <= 128'hffffffffffffffffffffffffffffffff;
            end

            // Test Case 7
            3'b111: begin
                selected_ct   <= 128'ha1f6258c877d5fcd8964484538bfc92c; // Fixed per your request
                selected_key  <= 128'hffffffffffffffffffffffffffffffff;
                expected_pt   <= 128'h00000000000000000000000000000000;
            end


            default: begin
                selected_ct   <= 128'h0;
                selected_key  <= 128'h0;
                expected_pt   <= 128'h0;
            end
        endcase
    end

    //--------------------------------------------------------------------------
    // 2. Instantiate your AES Decryption Core
    //    Connecting to your provided "Top_Module" interface
    //--------------------------------------------------------------------------
    Top_Module u_decrypt (
        .clk         (clk),
        .rst_n       (core_rst),           // Active-low reset
        .valid_in    (aes_start),          // Start signal
        .cipher_text (selected_ct),        // Input Ciphertext
        .key_in      (selected_key),       // Input Key
        .plain_text  (actual_pt_from_aes), // Output Plaintext
        .valid_out   (aes_done)            // Done signal
    );

    //--------------------------------------------------------------------------
    // 3. Simplified "Single-Shot" State Machine (Asynchronous Active-Low Reset)
    //--------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // --- Reset is pressed (active-low) ---
            state       <= STATE_IDLE;
            aes_start   <= 1'b0;
            led_success <= 1'b0;
            led_fail    <= 1'b0;
            
            // Assuming your Top_Module uses ACTIVE-LOW reset like your encryption core:
            core_rst    <= 1'b0; // Assert Reset (Low)
        end
        else begin
            // --- Reset is released ---
            core_rst    <= 1'b1; // De-assert Reset (High)
            aes_start   <= 1'b0; // Pulse is only 1 cycle

            case (state)
                STATE_IDLE: begin
                    state <= STATE_START_AES;
                end
                
                STATE_START_AES: begin
                    aes_start <= 1'b1;  // <-- PULSE valid_in
                    state <= STATE_WAIT_AES;
                end
                
                STATE_WAIT_AES: 
					 begin
                    if (aes_done) begin // Wait for valid_out
                        // Compare Decrypted output with Expected Plaintext
                    if (actual_pt_from_aes == expected_pt) begin
                        led_success <= 1'b1;
								led_fail <= 1'b0;
                    end else begin
						      led_success <= 1'b0;
                        led_fail <= 1'b1;
                    end
                    state <= STATE_DONE_LATCH;
                    end
                end
                    
                
                STATE_DONE_LATCH: begin
                    state <= STATE_DONE_LATCH;
                end

                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule