module AES_KeyExpansion_Reverse_calc 
(
    input wire [31:0] word_in_0,
    input wire [31:0] word_in_1,
    input wire [31:0] word_in_2,
    input wire [31:0] word_in_3,

    //input wire [3:0] round_number,
    
    input wire [31:0] word_from_g_func,
    output wire [31:0] word_to_g_func,

    output reg [31:0] previous_round_word_0,
    output reg [31:0] previous_round_word_1,
    output reg [31:0] previous_round_word_2,
    output reg [31:0] previous_round_word_3
);

    wire [31:0] g_function_out;
    //rather than makign another instance of g_function module in AES_keyExpansion_Reverse_calc.v, we can use the one in AES_keyExpansion_Forward_calc.v
    /*
    g_function g_function_instance(
        .word_in(previous_round_word_3), //use previous_round_word_3 here to reverse the operation
        .round_number(round_number),
        .word_out(g_function_out)
    );
    */
    assign word_to_g_func = previous_round_word_3;
    //round number in known in AES_KeyExpansion_Forward_calc.v, so no need to pass it here again
    assign g_function_out = word_from_g_func;

    //why always block here?
    //due to next_round_word_1 depend on new value of next_round_word_0, and so on.

    always @(*) begin
        previous_round_word_3 = word_in_3 ^ word_in_2;
        previous_round_word_2 = word_in_2 ^ word_in_1;
        previous_round_word_1 = word_in_1 ^ word_in_0;
        previous_round_word_0 = word_in_0 ^ g_function_out;
    end

endmodule //AES_KeyExpansion_Reverse_calc