module last_round 
(
    input   [127:0] pt,
    input   [127:0] kn,
    output  [127:0] ct
);

wire [127:0] substituted_state_array;
wire [127:0] shifted_state_array;


sub_bytes byte_substitution (.resultant_state_array(pt), .substituted_state_array(substituted_state_array)); //1st step


shift_row rows_shifted (.substituted_state_array(substituted_state_array), .shifted_state_array(shifted_state_array)); // 2nd step


Add_Round_Key xor_with_k1 (.plain_text(shifted_state_array), .key(kn), .resultant_state_array(ct)); // 3rd step

endmodule



/*
this module os for the lat round only because we do not do the mix_column step
*/