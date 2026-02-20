module aes_clock_gated_top #(parameter BLOCK_LENGTH = 128) (
    input  wire                      clk,    // Main system clock
    input  wire                      rst,    // Active low reset

    // Power/Clock Domain Enables
    input  wire                      pwr_en_enc, // 1 = Clock ON Encryptor
    input  wire                      pwr_en_dec, // 1 = Clock ON Decryptor

    // Shared Key Input
    input  wire [BLOCK_LENGTH-1:0]   KEY,

    // Encryptor Interface
    input  wire [BLOCK_LENGTH-1:0]   enc_IN,
    input  wire                      enc_enable,
    input  wire                      enc_fsm_en,
    output wire [BLOCK_LENGTH-1:0]   enc_OUT,
    output wire                      enc_valid_out,

    // Decryptor Interface
    input  wire [BLOCK_LENGTH-1:0]   dec_IN,
    input  wire                      dec_enable,
    input  wire                      dec_fsm_en,
    output wire [BLOCK_LENGTH-1:0]   dec_OUT,
    output wire                      dec_valid_out
);

    // ==========================================
    // Clock Gating Buffers (Xilinx Primitives)
    // ==========================================
    wire clk_enc;
    wire clk_dec;

    // BUFGCE safely halts the clock without causing glitches.
    // This physically stops the flip-flops from toggling, saving dynamic power.
    BUFGCE u_bufgce_enc (
        .O  (clk_enc),    
        .CE (pwr_en_enc), 
        .I  (clk)         
    );

    BUFGCE u_bufgce_dec (
        .O  (clk_dec),    
        .CE (pwr_en_dec),
        .I  (clk)
    );

    // ==========================================
    // Internal wires from AES modules
    // ==========================================
    wire [BLOCK_LENGTH-1:0] enc_out_internal;
    wire                    enc_valid_out_internal;

    wire [BLOCK_LENGTH-1:0] dec_out_internal;
    wire                    dec_valid_out_internal;

    // ==========================================
    // AES Encrypt Domain Instantiation
    // ==========================================
    // Hold reset low when sleeping for a clean wake-up state
    wire enc_pwr_rst = rst & pwr_en_enc; 

    AES_enc #(
        .BLOCK_LENGTH(BLOCK_LENGTH)
    ) u_AES_enc (
        .clk        (clk_enc),                 // <-- Driven by Gated Clock
        .rst        (enc_pwr_rst),             // <-- Masked Reset
        .IN         (enc_IN),
        .KEY        (KEY),
        .enable     (enc_enable & pwr_en_enc), // Mask input enables
        .fsm_en     (enc_fsm_en & pwr_en_enc), 
        .OUT        (enc_out_internal),
        .valid_out  (enc_valid_out_internal)
    );

    // ==========================================
    // AES Decrypt Domain Instantiation
    // ==========================================
    wire dec_pwr_rst = rst & pwr_en_dec;

    AES_dec #(
        .BLOCK_LENGTH(BLOCK_LENGTH)
    ) u_AES_dec (
        .clk        (clk_dec),                 // <-- Driven by Gated Clock
        .rst        (dec_pwr_rst),             // <-- Masked Reset
        .IN         (dec_IN),
        .KEY        (KEY),
        .enable     (dec_enable & pwr_en_dec), // Mask input enables
        .fsm_en     (dec_fsm_en & pwr_en_dec), 
        .OUT        (dec_out_internal),
        .valid_out  (dec_valid_out_internal)
    );

    // ==========================================
    // Isolation Logic (Clamp to 0)
    // ==========================================
    // Forces outputs to 0 when the domain is disabled to prevent 
    // stale data or unknown states from polluting the rest of your system.
    
    assign enc_OUT       = pwr_en_enc ? enc_out_internal       : {BLOCK_LENGTH{1'b0}};
    assign enc_valid_out = pwr_en_enc ? enc_valid_out_internal : 1'b0;

    assign dec_OUT       = pwr_en_dec ? dec_out_internal       : {BLOCK_LENGTH{1'b0}};
    assign dec_valid_out = pwr_en_dec ? dec_valid_out_internal : 1'b0;

endmodule