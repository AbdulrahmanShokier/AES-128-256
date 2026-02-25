//there is two TB here first one to test values in between clock cycles
//second one to test the final output of the top module

/*
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

    // ---------------------------------------
    // TEST CASE 1
    // ---------------------------------------
    $display("\n========== TEST CASE 1 ==========\n");

    @(posedge clk);
    key_in      <= 128'h000102030405060708090a0b0c0d0e0f;
    cipher_text <= 128'h69c4e0d86a7b0430d8cdb78070b4c55a;
    valid_in    <= 1;

    @(posedge clk);
    valid_in <= 0;

    wait(valid_out === 1);

    $display("TC1 Completed at time %0t ns", $time);
    $display("Plaintext = %h", plain_text);


    // ---------------------------------------
    // TEST CASE 2
    // ---------------------------------------
    $display("\n========== TEST CASE 2 ==========\n");

    @(posedge clk);
    key_in      <= 128'h00000000000000000000000000000000;
    cipher_text <= 128'h66e94bd4ef8a2c3b884cfa59ca342b2e;
    valid_in    <= 1;

    @(posedge clk);
    valid_in <= 0;

    wait(valid_out === 1);

    $display("TC2 Completed at time %0t ns", $time);
    $display("Plaintext = %h", plain_text);


    // ---------------------------------------
    // TEST CASE 3
    // ---------------------------------------
    $display("\n========== TEST CASE 3 ==========\n");

    @(posedge clk);
    key_in      <= 128'h00000000000000000000000000000000;
    cipher_text <= 128'hc8a331ff8edd3db175e1545dbefb760b;
    valid_in    <= 1;

    @(posedge clk);
    valid_in <= 0;

    wait(valid_out === 1);

    $display("TC3 Completed at time %0t ns", $time);
    $display("Plaintext = %h", plain_text);


    // END SIM
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


*/
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
// Match Checker
// ----------------------
reg [127:0] expected_pt;
wire match;

assign match = (valid_out && (plain_text == expected_pt)) ? 1'b1 : 1'b0;

// ----------------------
// Clock Generation
// ----------------------
initial begin
    clk = 0;
    forever #5 clk = ~clk;   // 100 MHz
end

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

    // ---------------------------------------
    // TEST CASE 1
    // ---------------------------------------
    $display("\n========== TEST CASE 1 ==========\n");
    expected_pt <= 128'h3243f6a8885a308d313198a2e0370734;

    @(posedge clk);
    key_in      <= 128'h2b7e151628aed2a6abf7158809cf4f3c;
    cipher_text <= 128'h3925841d02dc09fbdc118597196a0b32;
    valid_in    <= 1;

    @(posedge clk);
    valid_in <= 0;

    wait(valid_out === 1);
    $display("TC1 Completed at time %0t ns | Plaintext = %h | Match? = %b", $time, plain_text, match);

    // ---------------------------------------
    // TEST CASE 2
    // ---------------------------------------
    $display("\n========== TEST CASE 2 ==========\n");
    expected_pt <= 128'h00112233445566778899aabbccddeeff;

    @(posedge clk);
    key_in      <= 128'h000102030405060708090a0b0c0d0e0f;
    cipher_text <= 128'h69c4e0d86a7b0430d8cdb78070b4c55a;
    valid_in    <= 1;

    @(posedge clk);
    valid_in <= 0;

    wait(valid_out === 1);
    $display("TC2 Completed at time %0t ns | Plaintext = %h | Match? = %b", $time, plain_text, match);

    // ---------------------------------------
    // TEST CASE 3
    // ---------------------------------------
    $display("\n========== TEST CASE 3 ==========\n");
    expected_pt <= 128'h6bc1bee22e409f96e93d7e117393172a;

    @(posedge clk);
    key_in      <= 128'h2b7e151628aed2a6abf7158809cf4f3c;
    cipher_text <= 128'h3ad77bb40d7a3660a89ecaf32466ef97;
    valid_in    <= 1;

    @(posedge clk);
    valid_in <= 0;

    wait(valid_out === 1);
    $display("TC3 Completed at time %0t ns | Plaintext = %h | Match? = %b", $time, plain_text, match);

    // ---------------------------------------
    // TEST CASE 4
    // ---------------------------------------
    $display("\n========== TEST CASE 4 ==========\n");
    expected_pt <= 128'h00112233445566778899aabbccddeeff;

    @(posedge clk);
    key_in      <= 128'h00000000000000000000000000000000;
    cipher_text <= 128'hc8a331ff8edd3db175e1545dbefb760b;
    valid_in    <= 1;

    @(posedge clk);
    valid_in <= 0;

    wait(valid_out === 1);
    $display("TC4 Completed at time %0t ns | Plaintext = %h | Match? = %b", $time, plain_text, match);

    // ---------------------------------------
    // TEST CASE 5
    // ---------------------------------------
    $display("\n========== TEST CASE 5 ==========\n");
    expected_pt <= 128'hffffffffffffffffffffffffffffffff;

    @(posedge clk);
    key_in      <= 128'hffffffffffffffffffffffffffffffff;
    cipher_text <= 128'hbcbf217cb280cf30b2517052193ab979;
    valid_in    <= 1;

    @(posedge clk);
    valid_in <= 0;

    wait(valid_out === 1);
    $display("TC5 Completed at time %0t ns | Plaintext = %h | Match? = %b", $time, plain_text, match);

    // ---------------------------------------
    // TEST CASE 6
    // ---------------------------------------
    $display("\n========== TEST CASE 6 ==========\n");
    expected_pt <= 128'h00000000000000000000000000000000;

    @(posedge clk);
    key_in      <= 128'hffffffffffffffffffffffffffffffff;
    cipher_text <= 128'ha1f6258c877d5fcd8964484538bfc92c;
    valid_in    <= 1;

    @(posedge clk);
    valid_in <= 0;

    wait(valid_out === 1);
    $display("TC6 Completed at time %0t ns | Plaintext = %h | Match? = %b", $time, plain_text, match);

    // ---------------------------------------
    // TEST CASE 7
    // ---------------------------------------
    $display("\n========== TEST CASE 7 ==========\n");
    expected_pt <= 128'h00000000000000000000000000000000;

    @(posedge clk);
    key_in      <= 128'h00000000000000000000000000000000;
    cipher_text <= 128'h66e94bd4ef8a2c3b884cfa59ca342b2e;
    valid_in    <= 1;

    @(posedge clk);
    valid_in <= 0;

    wait(valid_out === 1);
    $display("TC7 Completed at time %0t ns | Plaintext = %h | Match? = %b", $time, plain_text, match);

    // ---------------------------------------
    // TEST CASE 8
    // ---------------------------------------
    $display("\n========== TEST CASE 8 ==========\n");
    expected_pt <= 128'hfb7cb6b75d2c68cfd06645a8fda84a21;

    @(posedge clk);
    key_in      <= 128'h2b7e151628aed2a6abf7158809cf4f3c;
    cipher_text <= 128'hf5d3d58503b969de785895a96fdbaaf0;
    valid_in    <= 1;

    @(posedge clk);
    valid_in <= 0;

    wait(valid_out === 1);
    $display("TC8 Completed at time %0t ns | Plaintext = %h | Match? = %b", $time, plain_text, match);

    // END SIM
    #20;
    $stop;
end



endmodule
