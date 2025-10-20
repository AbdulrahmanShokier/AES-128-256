module encryption_128
(
    input [127:0] plain_text,
    input [127:0] key0,
    input [127:0] cipher_text
);

wire [127:0] round_key1,round_key2,round_key3,round_key4,round_key5,
             round_key6,round_key7,round_key8,round_key9,round_key10;


wire [127:0] ct_round1,ct_round2,ct_round3,ct_round4,ct_round5,
             ct_round6,ct_round7,ct_round8,ct_round9;

//////////////////////round 1////////////////////////

key_generator r_k_1(.key(key0) , .round_number(8'h01) , .round_key(round_key1));

first_round r1(.pt(plain_text) , .k0(key0) , .k1(round_key1) , .ct_after_1st_round(ct_round1));

//////////////////////round 2////////////////////////

key_generator r_k_2(.key(round_key1) , .round_number(8'h02) , .round_key(round_key2));

mid_rounds r2(.pt(ct_round1) , .kn_minus_1(round_key2) , .ct_after_nth_round(ct_round2));

//////////////////////round 3////////////////////////

key_generator r_k_3(.key(round_key2) , .round_number(8'h04) , .round_key(round_key3));

mid_rounds r3(.pt(ct_round2) , .kn_minus_1(round_key3) , .ct_after_nth_round(ct_round3));

//////////////////////round 4////////////////////////

key_generator r_k_4(.key(round_key3) , .round_number(8'h08) , .round_key(round_key4));

mid_rounds r4(.pt(ct_round3) , .kn_minus_1(round_key4) , .ct_after_nth_round(ct_round4));

//////////////////////round 5////////////////////////

key_generator r_k_5(.key(round_key4) , .round_number(8'h10) , .round_key(round_key5));

mid_rounds r5(.pt(ct_round4) , .kn_minus_1(round_key5) , .ct_after_nth_round(ct_round5));

//////////////////////round 6////////////////////////

key_generator r_k_6(.key(round_key5) , .round_number(8'h20) , .round_key(round_key6));

mid_rounds r6(.pt(ct_round5) , .kn_minus_1(round_key6) , .ct_after_nth_round(ct_round6));

//////////////////////round 7////////////////////////

key_generator r_k_7(.key(round_key6) , .round_number(8'h40) , .round_key(round_key7));

mid_rounds r7(.pt(ct_round6) , .kn_minus_1(round_key7) , .ct_after_nth_round(ct_round7));

//////////////////////round 8////////////////////////

key_generator r_k_8(.key(round_key7) , .round_number(8'h80) , .round_key(round_key8));

mid_rounds r8(.pt(ct_round7) , .kn_minus_1(round_key8) , .ct_after_nth_round(ct_round8));

//////////////////////round 9////////////////////////

key_generator r_k_9(.key(round_key8) , .round_number(8'h1B) , .round_key(round_key9));

mid_rounds r9(.pt(ct_round8) , .kn_minus_1(round_key9) , .ct_after_nth_round(ct_round9));

//////////////////////round 10////////////////////////

key_generator r_k_9(.key(round_key9) , .round_number(8'h36) , .round_key(round_key10));

last_round r10 (.pt(ct_round9) , .kn(round_key10), .ct(cipher_text));

endmodule