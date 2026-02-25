module AES_cascade_top #(parameter BLOCK_LENGTH = 128)
(
    input                         clk,
    input                         rst,
    input      [BLOCK_LENGTH-1:0] plaintext_in, // Original data in
    input      [BLOCK_LENGTH-1:0] key,          // Shared symmetric key
    input                         enable,       // Enables the encryption stage
    input                         fsm_en,       // Enables the FSMs
    
    output     [BLOCK_LENGTH-1:0] plaintext_out,// Final decrypted data out
    output                        valid_out     // High when plaintext_out is valid
);

    // Internal wires to connect encoder to decoder
    wire [BLOCK_LENGTH-1:0] internal_ciphertext;
    wire                    enc_valid;

    // ==========================================
    // AES Encoder Instantiation
    // ==========================================
    AES_enc #(
        .BLOCK_LENGTH(BLOCK_LENGTH)
    ) encoder_inst (
        .clk(clk),
        .rst(rst),
        .IN(plaintext_in),
        .KEY(key),
        .enable(enable),
        .fsm_en(fsm_en),
        .OUT(internal_ciphertext),  // Routed internally instead of to an output port
        .valid_out(enc_valid)
    );

    // ==========================================
    // AES Decoder Instantiation
    // ==========================================
    AES_dec #(
        .BLOCK_LENGTH(BLOCK_LENGTH)
    ) decoder_inst (
        .clk(clk),
        .rst(rst),
        .IN(internal_ciphertext),   // Receives the internal routed data
        .KEY(key),
        .enable(enc_valid),         // Decoder only enables when encoder output is valid
        .fsm_en(fsm_en),
        .OUT(plaintext_out),
        .valid_out(valid_out)
    );

endmodule