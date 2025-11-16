module sub_bytes 
(
    input              clk,
    input              asy_reset,
    input  [127:0] resultant_state_array,
    output [127:0] substituted_state_array
);



    always@(posedge clk or negedge asy_reset)
    begin
        if(!asy_reset)
        begin
            substituted_state_array <= 128'h0;
        end

        else 
        begin
            substituted_state_array <= temp_substituted_state_array ;

        end
    end


    wire [7:0] s0,  s1,  s2,  s3,
               s4,  s5,  s6,  s7,
               s8,  s9,  s10, s11,
               s12, s13, s14, s15;


    assign {s0, s4, s8,  s12,
            s1, s5, s9,  s13,
            s2, s6, s10, s14,
            s3, s7, s11, s15} = resultant_state_array;


    wire [7:0] sb0,  sb1,  sb2,  sb3,
               sb4,  sb5,  sb6,  sb7,
               sb8,  sb9,  sb10, sb11,
               sb12, sb13, sb14, sb15;

    AES_Sbox sbox0 (.in_byte(s0),  .out_byte(sb0));
    AES_Sbox sbox1 (.in_byte(s1),  .out_byte(sb1));
    AES_Sbox sbox2 (.in_byte(s2),  .out_byte(sb2));
    AES_Sbox sbox3 (.in_byte(s3),  .out_byte(sb3));
    AES_Sbox sbox4 (.in_byte(s4),  .out_byte(sb4));
    AES_Sbox sbox5 (.in_byte(s5),  .out_byte(sb5));
    AES_Sbox sbox6 (.in_byte(s6),  .out_byte(sb6));
    AES_Sbox sbox7 (.in_byte(s7),  .out_byte(sb7));
    AES_Sbox sbox8 (.in_byte(s8),  .out_byte(sb8));
    AES_Sbox sbox9 (.in_byte(s9),  .out_byte(sb9));
    AES_Sbox sbox10(.in_byte(s10), .out_byte(sb10));
    AES_Sbox sbox11(.in_byte(s11), .out_byte(sb11));
    AES_Sbox sbox12(.in_byte(s12), .out_byte(sb12));
    AES_Sbox sbox13(.in_byte(s13), .out_byte(sb13));
    AES_Sbox sbox14(.in_byte(s14), .out_byte(sb14));
    AES_Sbox sbox15(.in_byte(s15), .out_byte(sb15));



    reg [127:0] temp_substituted_state_array;


    assign temp_substituted_state_array = {
        sb0, sb4, sb8, sb12,
        sb1, sb5, sb9, sb13,
        sb2, sb6, sb10, sb14,
        sb3, sb7, sb11, sb15
    };

endmodule
