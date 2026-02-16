//==============================================================================
// Module: key_generator_dec_optimized
// Description: Optimized AES-128 key expansion for decryption
// Resource Usage: 256 flip-flops (vs 1408 in original)
// Features: 
//   - Sequential key generation (one key per enable cycle)
//   - Minimal resource usage
//   - Pipelined output
//==============================================================================
module key_generator_dec #(
    parameter BLOCK_LENGTH = 128
)
(   
    input  wire                      clk,
    input  wire                      rst,           // Active low reset
    input  wire                      en,            // Enable signal from FSM
    input  wire [BLOCK_LENGTH-1:0]   key,           // Initial key (K0)
    input  wire [3:0]                Round_Count,   // Current round (0-10)
    output reg  [BLOCK_LENGTH-1:0]   current_key,   // Current round key
//    output reg                       key_valid      // Key valid flag
);

//==============================================================================
// Internal Registers and Wires
//==============================================================================
reg  [127:0] prev_key;              // Previous round key for expansion
wire [31:0]  w0, w1, w2, w3;        // Current key words
wire [31:0]  g_out;                 // G-function output
wire [31:0]  w4, w5, w6, w7;        // Next key words
wire [7:0]   round_const;           // AES round constant
wire [127:0] next_key;              // Computed next key

//==============================================================================
// Key Expansion Logic
//==============================================================================
// Extract 32-bit words from previous key
assign w0 = prev_key[127:96];
assign w1 = prev_key[95:64];
assign w2 = prev_key[63:32];
assign w3 = prev_key[31:0];

// G-function instantiation
g_function g_func (
    .word_3(w3),
    .round_number(round_const),
    .word_3_substituted(g_out)
);

// Key expansion XOR chain
assign w4 = w0 ^ g_out;
assign w5 = w1 ^ w4;
assign w6 = w2 ^ w5;
assign w7 = w3 ^ w6;

// Assemble next round key
assign next_key = {w4, w5, w6, w7};

//==============================================================================
// Sequential Logic - Key Generation State Machine
//==============================================================================
always @(posedge clk) begin
    if (!rst) begin
        prev_key    <= 128'b0;
        current_key <= 128'b0;
        key_valid   <= 1'b0;
    end
    else if (en) begin
        key_valid <= 1'b1;
        if (Round_Count == 4'd0) begin
            // Load initial key
            prev_key    <= key;
            current_key <= key;
        end
        else if (Round_Count <= 4'd10) begin
            // Generate and output next round key
            prev_key    <= next_key;
            current_key <= next_key;
        end
    end
    else begin
        key_valid <= 1'b0;
    end
end

//==============================================================================
// Round Constant Generation (Optimized LUT-based)
//==============================================================================


function [7:0] get_round_constant;
    input [3:0] round;
    begin
        case (round)
            4'd1:    get_round_constant = 8'h01;
            4'd2:    get_round_constant = 8'h02;
            4'd3:    get_round_constant = 8'h04;
            4'd4:    get_round_constant = 8'h08;
            4'd5:    get_round_constant = 8'h10;
            4'd6:    get_round_constant = 8'h20;
            4'd7:    get_round_constant = 8'h40;
            4'd8:    get_round_constant = 8'h80;
            4'd9:    get_round_constant = 8'h1B;
            4'd10:   get_round_constant = 8'h36;
            default: get_round_constant = 8'h00;
        endcase
    end
endfunction

assign round_const = get_round_constant(Round_Count);
endmodule