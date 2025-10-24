    module mid_rounds 
    (
        input           clk,
        input           asy_reset, 
        input   [127:0] pt,
        input   [127:0] kn_minus_1,
        output  [127:0] ct_after_nth_round
    );

    wire [127:0] substituted_state_array;
    wire [127:0] shifted_state_array;
    wire [127:0] mixed_state_array;


    sub_bytes byte_substitution (.clk(clk), .asy_reset(asy_reset), .resultant_state_array(pt), .substituted_state_array(substituted_state_array)); //1st step


    shift_row rows_shifted (.clk(clk), .asy_reset(asy_reset), .substituted_state_array(substituted_state_array), .shifted_state_array(shifted_state_array)); // 2nd step


    mix_columns columns_mixed(.clk(clk), .asy_reset(asy_reset), .shifted_state_array(shifted_state_array), .mixed_state_array(mixed_state_array)); // 3rd step


    Add_Round_Key xor_with_kn_minus_1 (.clk(clk), .asy_reset(asy_reset), .plain_text(mixed_state_array), .key(kn_minus_1), .resultant_state_array(ct_after_nth_round)); // 4th step

    endmodule



    /*
    this module is for the mid rounds only because we do the mix_column once but in the last round we don't do it
    */