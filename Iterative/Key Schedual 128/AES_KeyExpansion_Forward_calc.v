module AES_KeyExpansion_Forward_calc 
(
    input wire [31:0] word_in_0,
    input wire [31:0] word_in_1,
    input wire [31:0] word_in_2,
    input wire [31:0] word_in_3,

    input wire [3:0] round_number,

    output reg [31:0] next_round_word_0,
    output reg [31:0] next_round_word_1,
    output reg [31:0] next_round_word_2,
    output reg [31:0] next_round_word_3
);

    wire [31:0] g_function_out;
    wire [31:0] wordIn0_AddWith_gFunctionOut;    

    g_function g_func_instance(
        .word_in(word_in_3),
        .round_number(round_number),
        .word_out(g_function_out)
    );

    assign wordIn0_AddWith_gFunctionOut = word_in_0 ^ g_function_out;


    //why always block here?
    //due to next_round_word_1 depend on new value of next_round_word_0, and so on.

    always @(*) begin
        next_round_word_0 = wordIn0_AddWith_gFunctionOut;
        next_round_word_1 = next_round_word_0 ^ word_in_1;
        next_round_word_2 = next_round_word_1 ^ word_in_2;
        next_round_word_3 = next_round_word_2 ^ word_in_3;
    end





endmodule //AES_KeyExpansion_Forward_calc
