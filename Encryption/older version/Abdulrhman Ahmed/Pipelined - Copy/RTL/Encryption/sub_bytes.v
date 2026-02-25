module sub_bytes #(parameter BLOCK_LENGTH = 128)
(
    input  wire                    clk,
    input  wire                    rst, 
    input  wire [BLOCK_LENGTH-1:0] IN, 
    output reg  [BLOCK_LENGTH-1:0] OUT
);
    wire [7:0] s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15;
    wire [7:0] sb0, sb1, sb2, sb3, sb4, sb5, sb6, sb7, sb8, sb9, sb10, sb11, sb12, sb13, sb14, sb15;

    // Slicing 
    assign {s0, s1, s2, s3,
            s4, s5, s6, s7,
            s8, s9, s10, s11,
            s12, s13, s14, s15} = IN;

    S_box sbox0 (.in_byte(s0) , .out_byte(sb0) );
    S_box sbox1 (.in_byte(s1) , .out_byte(sb1) );
    S_box sbox2 (.in_byte(s2) , .out_byte(sb2) );
    S_box sbox3 (.in_byte(s3) , .out_byte(sb3) );
    S_box sbox4 (.in_byte(s4) , .out_byte(sb4) );
    S_box sbox5 (.in_byte(s5) , .out_byte(sb5) );
    S_box sbox6 (.in_byte(s6) , .out_byte(sb6) );
    S_box sbox7 (.in_byte(s7) , .out_byte(sb7) );
    S_box sbox8 (.in_byte(s8) , .out_byte(sb8) );
    S_box sbox9 (.in_byte(s9) , .out_byte(sb9) );
    S_box sbox10(.in_byte(s10), .out_byte(sb10));
    S_box sbox11(.in_byte(s11), .out_byte(sb11));
    S_box sbox12(.in_byte(s12), .out_byte(sb12));
    S_box sbox13(.in_byte(s13), .out_byte(sb13));
    S_box sbox14(.in_byte(s14), .out_byte(sb14));
    S_box sbox15(.in_byte(s15), .out_byte(sb15));

    // Pipeline register for BRAM inference
    always @(posedge clk) begin
        if (!rst) begin
            OUT <= 128'b0;
        end else begin
            OUT <= {
                sb0, sb1, sb2, sb3,
                sb4, sb5, sb6, sb7,
                sb8, sb9, sb10, sb11,
                sb12, sb13, sb14, sb15
            };
        end
    end
endmodule