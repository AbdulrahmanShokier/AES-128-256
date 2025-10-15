//=========================================================
// AES_KeyExpansion.v
// Description : AES Key Expansion (Generates w[i] words)
// Depends on   : AES_config.v
//=========================================================

`include "AES_config.v"

module AES_KeyExpansion(
    input  wire [KEY_SIZE-1:0] cipher_key,         // Initial AES key
    output reg  [32*Nb*(Nr+1)-1:0] round_keys      // Expanded key schedule
);

    // Internal variables
    reg [31:0] w [0:Nb*(Nr+1)-1];
    reg [31:0] temp;
    integer i;

    //=========================================================
    // Helper functions
    //=========================================================

    // Round Constant function (placeholder)
    function [31:0] RoundConstant;
        input integer round;
        begin
            RoundConstant = {8'h01 << (round-1), 24'h000000};  // To be replaced
        end
    endfunction

    // SubWord (to be replaced with S-box lookup)
   function [31:0] SubWord;
    input [31:0] word_in;
    reg [7:0] SBox [0:255];
    integer i;
    reg [7:0] b0, b1, b2, b3;

    begin
        // Initialize SBox (partial, fill full table later)
        SBox[8'h00] = 8'h63; SBox[8'h01] = 8'h7c; SBox[8'h02] = 8'h77; SBox[8'h03] = 8'h7b;
        SBox[8'h04] = 8'hf2; SBox[8'h05] = 8'h6b; SBox[8'h06] = 8'h6f; SBox[8'h07] = 8'hc5;
        SBox[8'h08] = 8'h30; SBox[8'h09] = 8'h01; SBox[8'h0a] = 8'h67; SBox[8'h0b] = 8'h2b;
        // ... continue full S-box table (256 entries)

        // Split bytes
        b3 = word_in[31:24];
        b2 = word_in[23:16];
        b1 = word_in[15:8];
        b0 = word_in[7:0];

        // Substitute each byte
        SubWord = {SBox[b3], SBox[b2], SBox[b1], SBox[b0]};
    end
    endfunction

    // RotateWord (byte rotation)
    function [31:0] RotateWord;
        input [31:0] word_in;
        begin
            RotateWord = {word_in[23:0], word_in[31:24]};//rotate left by 8 bits
        end
    endfunction

    //=========================================================
    // Key Expansion Logic
    //=========================================================

    //to remember: 
    //Nk is number of 32-bit words in the key
    //Nb is number of 32-bit words in the block (always 4 for AES)
    //Nr is number of rounds

    always @(*) begin
        // Step 1: Copy and split original key words into w[0..Nk-1]
        for (i = 0; i < Nk; i = i + 1) begin
            w[i] = cipher_key[KEY_SIZE - 32*(i+1) +: 32];
        end

        // Step 2: Generate expanded key words
        for (i = Nk; i < Nb*(Nr+1); i = i + 1) begin
            temp = w[i-1];
            if (i % Nk == 0)// If i is multiple of 4
                temp = SubWord(RotateWord(temp)) ^ RoundConstant(i / Nk);
            else if (Nk > 6 && (i % Nk == 4))
                temp = SubWord(temp);
            w[i] = w[i - Nk] ^ temp;
        end

        // Step 3: Concatenate all words into one output
        for (i = 0; i < Nb*(Nr+1); i = i + 1)
            round_keys[(Nb*(Nr+1)-i)*32-1 -: 32] = w[i];
    end

endmodule
