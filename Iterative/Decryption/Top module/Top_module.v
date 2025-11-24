// ------------------------------------------------------------------
// Top Module integrating FSM_controller, AES_Top, AES_key_schedular
// ------------------------------------------------------------------
module Top_Module (
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    input wire [127:0] cipher_text,
    input wire [127:0] key_in,
    output wire [127:0] plain_text,
    output wire valid_out,


    output wire [127:0] keyexp_roundkey_test
);


// ---------------------------
// Internal Signals
// ---------------------------
wire [127:0] keyexp_load_key;
wire [127:0] roundkey_from_keyexp;
wire [1:0] keyexp_control;
wire [3:0]round_number;
wire Decryptor_enbale;
wire Decryptor_store_CT;


// ---------------------------
// FSM Controller
// ---------------------------
FSM_controller FSM_U (
    .clk(clk),
    .rst_n(rst_n),
    .vaild_in(valid_in),
    .key_in(key_in),
    .vaild_out(valid_out),
    .round_count_to_keyExp(round_number),
    .KeyOut_KeyExpLoad(keyexp_load_key),
    .KeyExp_RoundKey(roundkey_from_keyexp),
    .KeyExp_control(keyexp_control),
    .Decryptor_en(Decryptor_enbale)
);


// ---------------------------
// AES Key Scheduler
// ---------------------------
AES_key_schedular KEYEXP_U (
    .clk(clk),
    .control_signal(keyexp_control),
    .load_key_in(keyexp_load_key),
    .round_number(round_number),
    .round_key_out(roundkey_from_keyexp)
);


// ---------------------------
// Extra Testing Wires
// ---------------------------
wire [127:0] round_plaintext_test;
wire aes_valid_test;

assign round_plaintext_test = plain_text; // tap plaintext output
assign keyexp_roundkey_test = roundkey_from_keyexp; // tap keyexp output


// ---------------------------
// AES Top (Decryption)
// ---------------------------
AES_Top AESDEC_U (
    .CLK(clk),
    .RST(rst_n),
    .En(Decryptor_enbale),           // Enable from FSM
    .Cipher_Text(cipher_text),       // Input ciphertext
    .RoundKey_i(roundkey_from_keyexp),    // Iterative round key from Key Scheduler
    .Round_Number(round_number),     // Round number from FSM
    .Plain_Text(plain_text),         // Output plaintext
);
                  


endmodule // Top_Module