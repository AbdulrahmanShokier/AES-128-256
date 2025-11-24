    // ------------------------------------------------------------------
    // AES Decryption Module (Iterative) with external round number
    // ------------------------------------------------------------------
    module AES_Decryption #(
        parameter BLOCK_LENGTH = 128
    )(
        input  wire                     CLK,
        input  wire                     RST,         // Active low reset
        input  wire                     En,          // Start decryption
        input  wire [BLOCK_LENGTH-1:0]  CT,          // Ciphertext input
        input  wire [BLOCK_LENGTH-1:0]  K_i,         // Round key input (current round)
        input  wire [3:0]               Round_Number, // Current round number (controlled externally)
        output wire [BLOCK_LENGTH-1:0]  PT,          // Plaintext output
        output reg                      Valid        // Output valid flag
    );

        // -----------------------------
        // Internal Registers
        // -----------------------------
        reg [BLOCK_LENGTH-1:0] CT_reg;      // Holds intermediate round results
        reg [BLOCK_LENGTH-1:0] CT_next;     // Next value to be loaded into CT_reg


        reg [BLOCK_LENGTH-1:0] SEL_InvShiftRows_input;

        // -----------------------------
        // Internal Wires
        // -----------------------------
        wire [BLOCK_LENGTH-1:0] Inv_AddKey_Out;
        wire [BLOCK_LENGTH-1:0] Inv_ShiftRow_Out;
        wire [BLOCK_LENGTH-1:0] Inv_SubByte_Out;
        wire [BLOCK_LENGTH-1:0] Inv_MixCol_Out;

        // -----------------------------
        // Instantiate AES Layers
        // -----------------------------
        key_add       KA_U1       (.IN(CT_reg),       .KEY(K_i),      .OUT(Inv_AddKey_Out));
        InvMixColumns MX_U1       (.IN(Inv_AddKey_Out),       .OUT(Inv_MixCol_Out));
        InvShiftRows  SR_U1       (.IN(SEL_InvShiftRows_input),   .OUT(Inv_ShiftRow_Out));
        InvSubBytes   SB_U1       (.IN(Inv_ShiftRow_Out), .OUT(Inv_SubByte_Out));

        // -----------------------------
        // Control Signals
        // -----------------------------
        wire SEL_FirstRound  = (Round_Number == 4'd10); // Use Inv_AddKey_Out as first input
        wire SEL_LastRound   = (Round_Number == 4'd0);  // Latch SubBytes output

        // -----------------------------
        // CT_next MUX
        // -----------------------------
        always @(*) begin
            if (SEL_LastRound)
                CT_next = Inv_AddKey_Out;       
            else
                CT_next = Inv_SubByte_Out;      // Subsequent rounds
        end

        //--------------------------
        // MUX for InvShiftRows input
        //-----------------------
        

        always @(*) begin
            if (SEL_FirstRound)
                SEL_InvShiftRows_input = Inv_AddKey_Out;
            else
                SEL_InvShiftRows_input = Inv_MixCol_Out;
        end

        // -----------------------------
        // CT_reg Latch
        // -----------------------------
        always @(posedge CLK or negedge RST) begin
            if (!RST) 
                CT_reg <= {BLOCK_LENGTH{1'b0}};
            else if (En) CT_reg <= CT_next;          // Register next value
            
            else CT_reg <= CT;
        end

        // -----------------------------
        // Output PT 
        // -----------------------------
        assign PT = CT_reg;                 // PT always shows current CT_reg

        

    endmodule
