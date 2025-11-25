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
