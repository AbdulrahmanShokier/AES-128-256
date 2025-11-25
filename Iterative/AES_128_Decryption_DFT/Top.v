module AES_Top #(parameter BLOCK_LENGTH = 128) (
    input  wire                     CLK,
    input  wire                     RST,
    input  wire                     En,
    input  wire [BLOCK_LENGTH-1:0]  Cipher_Text,  // 128-bit input ciphertext
    input  wire [BLOCK_LENGTH-1:0]  RoundKey_i,   // Iterative round key (changes each round)
    input  wire [3:0]               Round_Number, // Current round number from FSM
    output wire [BLOCK_LENGTH-1:0]  Plain_Text,   // 128-bit output plaintext
    output wire                     Valid          // High when plaintext output is valid
);

    // Instantiate the AES Decryption core (iterative version)
    AES_Decryption #(.BLOCK_LENGTH(BLOCK_LENGTH)) AES_Dec_U (
        .CLK(CLK),
        .RST(RST),
        .En(En),
        .CT(Cipher_Text),
        .K_i(RoundKey_i),
        .Round_Number(Round_Number),
        .PT(Plain_Text),
        .Valid(Valid)
    );

endmodule
