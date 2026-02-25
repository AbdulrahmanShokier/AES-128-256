`timescale 1ns/1ps

module TB_AES_KeyExpansion_Forward_calc;

    // Inputs
    reg [31:0] word_in_0;
    reg [31:0] word_in_1;
    reg [31:0] word_in_2;
    reg [31:0] word_in_3;
    reg [3:0]  round_number;

    // Outputs
    wire [31:0] next_round_word_0;
    wire [31:0] next_round_word_1;
    wire [31:0] next_round_word_2;
    wire [31:0] next_round_word_3;

    // Instantiate the DUT
    AES_KeyExpansion_Forward_calc DUT (
        .word_in_0(word_in_0),
        .word_in_1(word_in_1),
        .word_in_2(word_in_2),
        .word_in_3(word_in_3),
        .round_number(round_number),
        .next_round_word_0(next_round_word_0),
        .next_round_word_1(next_round_word_1),
        .next_round_word_2(next_round_word_2),
        .next_round_word_3(next_round_word_3)
    );

    // Clock not needed as all combinational
    initial begin
        $display("===== AES Key Expansion Forward Calc Test =====");
        $monitor("Time=%0t | round=%0d | W0=%h W1=%h W2=%h W3=%h | Next_Words: %h %h %h %h",
                  $time, round_number, word_in_0, word_in_1, word_in_2, word_in_3,
                  next_round_word_0, next_round_word_1, next_round_word_2, next_round_word_3);

        // --------------------------
        // TEST CASE 1 (change manually)
        // --------------------------
        word_in_0 = 32'h00000000;
        word_in_1 = 32'h00000000;
        word_in_2 = 32'h00000000;
        word_in_3 = 32'h00000000;
        round_number = 4'd1;

        #10; // wait for combinational outputs

        // --------------------------
        // TEST CASE 2 (change manually)
        // --------------------------
        word_in_0 = 32'h00000000;
        word_in_1 = 32'h00000000;
        word_in_2 = 32'h00000000;
        word_in_3 = 32'h33333333;
        round_number = 4'd2;

        #10;

        // Add more test cases here as needed
        $display("\n=== TEST COMPLETE ===");
        $stop;
    end

endmodule
