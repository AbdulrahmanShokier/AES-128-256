`timescale 1ns/1ps

module tb_Top_Module;

// ----------------------
// DUT Inputs
// ----------------------
reg clk;
reg rst_n;
reg valid_in;
reg [127:0] cipher_text;
reg [127:0] key_in;

// ----------------------
// DUT Outputs
// ----------------------
wire [127:0] plain_text;
wire valid_out;
wire [127:0] keyexp_roundkey_test;

// ----------------------
// Instantiate DUT
// ----------------------
Top_Module DUT (
    .clk(clk),
    .rst_n(rst_n),
    .valid_in(valid_in),
    .cipher_text(cipher_text),
    .key_in(key_in),
    .plain_text(plain_text),
    .valid_out(valid_out),
    .keyexp_roundkey_test(keyexp_roundkey_test)
);

// ----------------------
// Clock Generation
// ----------------------
initial begin
    clk = 0;
    forever #5 clk = ~clk;   // 100 MHz
end


// ----------------------
// Test vectors
// ----------------------
localparam [127:0] TEST_KEY =
    128'h2B7E151628AED2A6ABF7158809CF4F3C;

localparam [127:0] TEST_CT =
    128'h3925841D02DC09FBDC118597196A0B32;
    

// ----------------------
// MAIN TEST SEQUENCE
// ----------------------
initial begin
    
    // Initial values
    rst_n = 0;
    valid_in = 0;
    cipher_text = 0;
    key_in = 0;

    // Waveform dump
    $dumpfile("top_module_tb.vcd");
    $dumpvars(0, tb_Top_Module);

    // Reset
    #20;
    rst_n = 1;
    #20;

    // Apply cipher + key
    @(posedge clk);
    key_in      <= TEST_KEY;
    cipher_text <= TEST_CT;
    valid_in    <= 1;

    @(posedge clk);
    valid_in <= 0;

    // Wait for decrypt complete
    wait(valid_out === 1);

    $display("\n--------------------------------------------");
    $display("Decryption Completed at time %0t ns", $time);
    $display("Plaintext = %h", plain_text);
    $display("--------------------------------------------\n");

    #20;
    $stop;
end


// ----------------------
// MONITOR INTERNAL WIRES
// ----------------------
initial begin
    $display("Time\tState Info");
    $monitor(
        "t=%0t | valid_in=%b | valid_out=%b | round=%d | Dec_en=%b\n  KeyLoad=%h\n  KeyRound=%h\n  Plaintext=%h\n state=%h\n",
         $time,
         valid_in,
         valid_out,
         DUT.round_number,
         DUT.Decryptor_enbale,
         DUT.keyexp_load_key,
         DUT.keyexp_roundkey_test,
         DUT.round_plaintext_test,
         DUT.FSM_U.current_state
    );
end

endmodule
