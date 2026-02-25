
module g_function (
    input wire [31:0] word_in,
    input wire [3:0] round_number,

    output wire [31:0] word_out
);
    wire [7:0] v0,v1,v2,v3;//bytes of input word
    
    assign v0 = word_in[31:24];
    assign v1 = word_in[23:16];
    assign v2 = word_in[15:8];
    assign v3 = word_in[7:0];

    wire [7:0] s0,s1,s2,s3;//sbox output bytes
    //Bytes are rotated left by one position and passed through S-boxes
    AES_Sbox sbox0(.in_byte(v1), .out_byte(s0));
    AES_Sbox sbox1(.in_byte(v2), .out_byte(s1));
    AES_Sbox sbox2(.in_byte(v3), .out_byte(s2));
    AES_Sbox sbox3(.in_byte(v0), .out_byte(s3));


    wire [7:0] word_added_RC;

    RC_adder rc_adder_instance(
        .byte_in(s0),
        .round_number(round_number),
        .byte_out(word_added_RC)
    );

    assign word_out = {word_added_RC, s1, s2, s3};



endmodule //g_function