module AES_DFT (
    input wire clk,       // 100MHz clock from board
    input wire rst_n,     // Reset button (active-low)
    input wire [2:0] sw,  // 3 switches to select test vector
    
    output reg led_success, // LED<0>
    output reg led_fail     // LED<7>
);
    // --- Internal Registers and Wires ---
    reg [127:0] selected_pt;
    reg [127:0] selected_key;
    reg [127:0] expected_ct;
    wire [127:0] actual_ct_from_aes;
   
  	 wire          aes_done;
    reg          aes_start;
    reg          core_rst; // Internal reset for the AES core

    // --- State machine ---
    reg [2:0] state;
    localparam STATE_IDLE       = 3'b000; // Waiting for reset to be pressed/released
    localparam STATE_START_AES  = 3'b001; // Start the core
    localparam STATE_WAIT_AES   = 3'b010; // Wait for 'done'
    localparam STATE_COMPARE    = 3'b011; // Check the result
    localparam STATE_DONE_LATCH = 3'b100; // Hold the result on LEDs

    always @(posedge clk) begin
        case (sw)
            3'b000: begin
                selected_pt   <= 128'h3243f6a8885a308d313198a2e0370734;
                selected_key  <= 128'h2b7e151628aed2a6abf7158809cf4f3c;
                expected_ct   <= 128'h3925841d02dc09fbdc118597196a0b32;
            end
            
            3'b001: begin
                selected_pt   <= 128'h00112233445566778899aabbccddeeff;
                selected_key  <= 128'h000102030405060708090a0b0c0d0e0f;
                expected_ct   <= 128'h69c4e0d86a7b0430d8cdb78070b4c55a;
            end
            
            // Test Case 2
            3'b010: begin
                selected_pt   <= 128'h6bc1bee22e409f96e93d7e117393172a;
                selected_key  <= 128'h2b7e151628aed2a6abf7158809cf4f3c;
                expected_ct   <= 128'h3ad77bb40d7a3660a89ecaf32466ef97;
            end

            // Test Case 3
            3'b011: begin
                selected_pt   <= 128'hae2d8a571e03ac9c9eb76fac45af7;
                selected_key  <= 128'h2b7e151628aed2a6abf7158809cf4f3c;
                expected_ct   <= 128'hf5d3d58503b969de785895a96fdbaaf;
            end
            
            // Test Case 4
            3'b100: begin
                selected_pt   <= 128'h00000000000000000000000000000000;
                selected_key  <= 128'h00000000000000000000000000000000;
                expected_ct   <= 128'h66e94bd4ef8a2c3b884cfa59ca342b2e;
            end
            
            // Test Case 5
            3'b101: begin
                selected_pt   <= 128'h00112233445566778899aabbccddeeff;
                selected_key  <= 128'h00000000000000000000000000000000;
                expected_ct   <= 128'h8308b3b31059124483036a28c57b7fbf;
            end

            // Test Case 6
            3'b110: begin
                selected_pt   <= 128'hffffffffffffffffffffffffffffffff;
                selected_key  <= 128'hffffffffffffffffffffffffffffffff;
                expected_ct   <= 128'h81a85b436c61d369036a100a8c43c232;
            end

            // Test Case 7
            3'b111: begin
                selected_pt   <= 128'h00000000000000000000000000000000;
                selected_key  <= 128'hffffffffffffffffffffffffffffffff;
                expected_ct   <= 128'h79051d95d51d5f29c2035f8d87a40b95;
            end

            default: begin
                selected_pt   <= 128'h0;
                selected_key  <= 128'h0;
                expected_ct   <= 128'h0;
            end
        endcase
    end


    AES_Top #(.BLOCK_LENGTH(128),.KEY_LENGTH(128))
	 UUT (
        .CLK_top    (clk),
        .RST_top    (core_rst), 
        .En_top     (aes_start),
        .PT_top     (selected_pt),
        .M_KEY_top  (selected_key),
        .CT_top     (actual_ct_from_aes),
        .Valid_top  (aes_done)
        );

    // State Machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= STATE_IDLE;
            aes_start <= 1'b0;
            led_success <= 1'b0;
            led_fail <= 1'b0;
            core_rst <= 1'b0; 
        end
        else begin
            core_rst <= 1'b1;  
            aes_start <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    // After reset is released, move to START
                    state <= STATE_START_AES;
                end
                
                STATE_START_AES: begin
                    aes_start <= 1'b1;  // <-- PULSE En_top
                    state <= STATE_WAIT_AES;
                end
                
                STATE_WAIT_AES: begin
                    if (aes_done) begin
                        state <= STATE_COMPARE;
                    end
                    // else: stay in WAIT state
                end
                
                STATE_COMPARE: begin
                    if (actual_ct_from_aes == expected_ct) begin
                        led_success <= 1'b1;
								led_fail <= 1'b0;
                    end else begin
                        led_fail <= 1'b1;
								led_success <= 1'b0;
                    end
                    state <= STATE_DONE_LATCH;
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