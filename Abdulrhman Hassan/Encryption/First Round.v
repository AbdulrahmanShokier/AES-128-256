module first_round 
(
    input   [127:0] pt,
    input   [127:0] k0,
    input   [127:0] k1,
    output  [127:0] ct_after_1st_round
);

wire [127:0] resultant_state_array_k0;
wire [127:0] substituted_state_array;
wire [127:0] shifted_state_array;
wire [127:0] mixed_state_array;
wire [127:0] resultant_state_array_k1;

Add_Round_Key xor_with_k0 (.plain_text(pt), .key(k0), .resultant_state_array(resultant_state_array_k0)); // first step


sub_bytes byte_substitution (.resultant_state_array(resultant_state_array_k0), .substituted_state_array(substituted_state_array)); //second step


shift_row rows_shifted (.substituted_state_array(substituted_state_array), .shifted_state_array(shifted_state_array)); // third step


mix_columns coulmns_mixed(.shifted_state_array(shifted_state_array), .mixed_state_array(resultant_state_array_k1)); // fourth step


Add_Round_Key xor_with_k1 (.plain_text(resultant_state_array_k1), .key(k1), .resultant_state_array(ct_after_1st_round)); // fifth step

endmodule



/*
this module os for the first round only because we do the addition of the key twice but in every other step 
we do it once only at the end of the round
*/