
module InvSubBytes #(parameter BLOCK_LENGTH = 128)
(
    input  wire [BLOCK_LENGTH-1:0] IN ,
    output wire [BLOCK_LENGTH-1:0] OUT
);
    wire [7:0] s0, s1, s2, s3,
               s4, s5, s6, s7,
               s8, s9, s10, s11,
               s12, s13, s14, s15;

    assign {s0, s1, s2, s3,
            s4, s5, s6, s7,
            s8, s9, s10, s11,
            s12, s13, s14, s15} = IN;

    wire [7:0] sb0, sb1, sb2, sb3,
               sb4, sb5, sb6, sb7,
               sb8, sb9, sb10, sb11,
               sb12, sb13, sb14, sb15;

    AES_InvSbox sbox0 (.in_byte(s0),  .out_byte(sb0));
    AES_InvSbox sbox1 (.in_byte(s1),  .out_byte(sb1));
    AES_InvSbox sbox2 (.in_byte(s2),  .out_byte(sb2));
    AES_InvSbox sbox3 (.in_byte(s3),  .out_byte(sb3));
    AES_InvSbox sbox4 (.in_byte(s4),  .out_byte(sb4));
    AES_InvSbox sbox5 (.in_byte(s5),  .out_byte(sb5));
    AES_InvSbox sbox6 (.in_byte(s6),  .out_byte(sb6));
    AES_InvSbox sbox7 (.in_byte(s7),  .out_byte(sb7));
    AES_InvSbox sbox8 (.in_byte(s8),  .out_byte(sb8));
    AES_InvSbox sbox9 (.in_byte(s9),  .out_byte(sb9));
    AES_InvSbox sbox10(.in_byte(s10), .out_byte(sb10));
    AES_InvSbox sbox11(.in_byte(s11), .out_byte(sb11));
    AES_InvSbox sbox12(.in_byte(s12), .out_byte(sb12));
    AES_InvSbox sbox13(.in_byte(s13), .out_byte(sb13));
    AES_InvSbox sbox14(.in_byte(s14), .out_byte(sb14));
    AES_InvSbox sbox15(.in_byte(s15), .out_byte(sb15));

    assign OUT = {
        sb0, sb1, sb2, sb3,
        sb4, sb5, sb6, sb7,
        sb8, sb9, sb10, sb11,
        sb12, sb13, sb14, sb15
    };

endmodule


