module AES_KeyExpansion_Reverse_calc 
(
    input wire [31:0] word_in_0,
    input wire [31:0] word_in_1,
    input wire [31:0] word_in_2,
    input wire [31:0] word_in_3,

    input wire [3:0] round_number,

    output reg [31:0] previous_round_word_0,
    output reg [31:0] previous_round_word_1,
    output reg [31:0] previous_round_word_2,
    output reg [31:0] previous_round_word_3
);

    wire [31:0] g_function_out;

    g_function g_function_instance(
        .word_in(previous_round_word_3), //use previous_round_word_3 here to reverse the operation
        .round_number(round_number),
        .word_out(g_function_out)
    );

    //why always block here?
    //due to next_round_word_1 depend on new value of next_round_word_0, and so on.

    always @(*) begin
        previous_round_word_3 = word_in_3 ^ word_in_2;
        previous_round_word_2 = word_in_2 ^ word_in_1;
        previous_round_word_1 = word_in_1 ^ word_in_0;
        previous_round_word_0 = word_in_0 ^ g_function_out;
    end

endmodule //AES_KeyExpansion_Reverse_calc