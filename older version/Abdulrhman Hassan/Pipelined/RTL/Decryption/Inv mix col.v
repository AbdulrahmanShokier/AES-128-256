module InvMixColumns  #(parameter BLOCK_LENGTH = 128)
(
    input wire  [BLOCK_LENGTH-1:0] IN,
    output wire [BLOCK_LENGTH-1:0] OUT
);

    function [7:0] gm2(input [7:0] a);
        gm2 = (a << 1) ^ ((a[7]) ? 8'h1b : 8'h00);
    endfunction

    function [7:0] gm9(input [7:0] a);
        gm9 = gm2(gm2(gm2(a))) ^ a;
    endfunction

    function [7:0] gm11(input [7:0] a);
        gm11 = gm2(gm2(gm2(a))) ^ gm2(a) ^ a;
    endfunction

    function [7:0] gm13(input [7:0] a);
        gm13 = gm2(gm2(gm2(a))) ^ gm2(gm2(a)) ^ a;
    endfunction
    
    function [7:0] gm14(input [7:0] a);
        gm14 = gm2(gm2(gm2(a))) ^ gm2(gm2(a)) ^ gm2(a);
    endfunction

    wire [7:0] s[0:15];
    assign {s[0], s[1], s[2], s[3],
            s[4], s[5], s[6], s[7],
            s[8], s[9], s[10], s[11],
            s[12], s[13], s[14], s[15]} = IN ;

    wire [7:0] m[0:15];

    assign m[0]  = gm14(s[0]) ^ gm11(s[1]) ^ gm13(s[2]) ^ gm9(s[3]);
    assign m[1]  = gm9(s[0])  ^ gm14(s[1]) ^ gm11(s[2]) ^ gm13(s[3]);
    assign m[2]  = gm13(s[0]) ^ gm9(s[1])  ^ gm14(s[2]) ^ gm11(s[3]);
    assign m[3]  = gm11(s[0]) ^ gm13(s[1]) ^ gm9(s[2])  ^ gm14(s[3]);

    assign m[4]  = gm14(s[4]) ^ gm11(s[5]) ^ gm13(s[6]) ^ gm9(s[7]);
    assign m[5]  = gm9(s[4])  ^ gm14(s[5]) ^ gm11(s[6]) ^ gm13(s[7]);
    assign m[6]  = gm13(s[4]) ^ gm9(s[5])  ^ gm14(s[6]) ^ gm11(s[7]);
    assign m[7]  = gm11(s[4]) ^ gm13(s[5]) ^ gm9(s[6])  ^ gm14(s[7]);

    assign m[8]  = gm14(s[8]) ^ gm11(s[9]) ^ gm13(s[10]) ^ gm9(s[11]);
    assign m[9]  = gm9(s[8])  ^ gm14(s[9]) ^ gm11(s[10]) ^ gm13(s[11]);
    assign m[10] = gm13(s[8]) ^ gm9(s[9])  ^ gm14(s[10]) ^ gm11(s[11]);
    assign m[11] = gm11(s[8]) ^ gm13(s[9]) ^ gm9(s[10]) ^ gm14(s[11]);

    assign m[12] = gm14(s[12]) ^ gm11(s[13]) ^ gm13(s[14]) ^ gm9(s[15]);
    assign m[13] = gm9(s[12])  ^ gm14(s[13]) ^ gm11(s[14]) ^ gm13(s[15]);
    assign m[14] = gm13(s[12]) ^ gm9(s[13])  ^ gm14(s[14]) ^ gm11(s[15]);
    assign m[15] = gm11(s[12]) ^ gm13(s[13]) ^ gm9(s[14]) ^ gm14(s[15]);

    assign OUT = {m[0], m[1], m[2], m[3],
                        m[4], m[5], m[6], m[7],
                        m[8], m[9], m[10], m[11],
                        m[12], m[13], m[14], m[15]};
endmodule

