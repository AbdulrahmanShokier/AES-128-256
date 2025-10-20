module g_function
(
    input  [31:0] word_3,
    input  [7 :0] round_number,
    output [31:0] word_3_substituted
);

wire [7:0] v0;
wire [7:0] v1;
wire [7:0] v2;
wire [7:0] v3;


AES_Sbox v3_out (.in_byte(word_3[7 : 0]) , .out_byte(v3));
AES_Sbox v2_out (.in_byte(word_3[15: 8]) , .out_byte(v2));
AES_Sbox v1_out (.in_byte(word_3[23:16]) , .out_byte(v1));
AES_Sbox v0_out (.in_byte(word_3[31:24]) , .out_byte(v0));

assign word_3_substituted = {v1 ^ round_number,v2,v3,v0} ;


endmodule

/*

v0 اكبر ببايت هو اللي في ال 

*/