`timescale 1ns/1ps

module encryption_128_tb;

// Inputs
reg [127:0] plain_text;
reg [127:0] key0;

// Output
wire [127:0] cipher_text;

// Instantiate the Unit Under Test (UUT)
encryption_128 uut (
    .plain_text(plain_text),
    .key0(key0),
    .cipher_text(cipher_text)
);

initial begin
    // Display Header
    $display("------------------------------------------------------");
    $display(" AES-128 Encryption Testbench ");
    $display("------------------------------------------------------");

    // Test Vector from AES Standard (FIPS-197)
    // Plaintext = 00112233445566778899AABBCCDDEEFF
    // Key       = 000102030405060708090A0B0C0D0E0F
    // Expected Ciphertext = 69C4E0D86A7B0430D8CDB78070B4C55A

    plain_text = 128'h00112233445566778899AABBCCDDEEFF;
    key0       = 128'h000102030405060708090A0B0C0D0E0F;

    // Wait for combinational logic to settle
    #10;

    // Display Results
    $display("Plaintext     = %h", plain_text);
    $display("Key           = %h", key0);
    $display("Ciphertext    = %h", cipher_text);
    $display("Expected Out  = 69C4E0D86A7B0430D8CDB78070B4C55A");

    // Compare results (optional check)
    if (cipher_text == 128'h69C4E0D86A7B0430D8CDB78070B4C55A)
        $display("✅ AES Encryption PASSED!");
    else
        $display("❌ AES Encryption FAILED!");

    $display("------------------------------------------------------");

    // End simulation
    #10;
    $stop;
end

endmodule
