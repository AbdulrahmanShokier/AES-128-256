module mix_columns 
(
    input  [127:0] shifted_state_array,
    output [127:0] mixed_state_array
);

    // Split state into bytes (column-major order)
    wire [7:0] s [0:15];

    assign {s[0], s[1], s[2], s[3],
            s[4], s[5], s[6], s[7],
            s[8], s[9], s[10], s[11],
            s[12], s[13], s[14], s[15]} = shifted_state_array;

    // Function for multiply by 2 in GF(2^8)

    function [7:0] xtime(input [7:0] x);
        begin
            xtime = (x[7]) ? ((x << 1) ^ 8'h1b) : (x << 1);
        end
    endfunction

    // Multiply by 2 and 3 (3*x = 2*x ^ x)
    function [7:0] mul2(input [7:0] x);
        mul2 = xtime(x);
    endfunction

    function [7:0] mul3(input [7:0] x);
        mul3 = xtime(x) ^ x;
    endfunction

    // Each column after MixColumns
    wire [7:0] m [0:15];

    // Column 0 (s0,s1,s2,s3)
    assign m[0] =  mul2(s[0]) ^ mul3(s[1]) ^ s[2] ^ s[3];
    assign m[1] =  s[0] ^ mul2(s[1]) ^ mul3(s[2]) ^ s[3];
    assign m[2] =  s[0] ^ s[1] ^ mul2(s[2]) ^ mul3(s[3]);
    assign m[3] =  mul3(s[0]) ^ s[1] ^ s[2] ^ mul2(s[3]);

    // Column 1 (s4,s5,s6,s7)
    assign m[4] =  mul2(s[4]) ^ mul3(s[5]) ^ s[6] ^ s[7];
    assign m[5] =  s[4] ^ mul2(s[5]) ^ mul3(s[6]) ^ s[7];
    assign m[6] =  s[4] ^ s[5] ^ mul2(s[6]) ^ mul3(s[7]);
    assign m[7] =  mul3(s[4]) ^ s[5] ^ s[6] ^ mul2(s[7]);

    // Column 2 (s8,s9,s10,s11)
    assign m[8]  = mul2(s[8])  ^ mul3(s[9])  ^ s[10] ^ s[11];
    assign m[9]  = s[8]  ^ mul2(s[9])  ^ mul3(s[10]) ^ s[11];
    assign m[10] = s[8]  ^ s[9]  ^ mul2(s[10]) ^ mul3(s[11]);
    assign m[11] = mul3(s[8])  ^ s[9]  ^ s[10] ^ mul2(s[11]);

    // Column 3 (s12,s13,s14,s15)
    assign m[12] = mul2(s[12]) ^ mul3(s[13]) ^ s[14] ^ s[15];
    assign m[13] = s[12] ^ mul2(s[13]) ^ mul3(s[14]) ^ s[15];
    assign m[14] = s[12] ^ s[13] ^ mul2(s[14]) ^ mul3(s[15]);
    assign m[15] = mul3(s[12]) ^ s[13] ^ s[14] ^ mul2(s[15]);

    // Combine output bytes back into 128-bit state
    assign mixed_state_array = {
        m[0],  m[1],  m[2],  m[3],
        m[4],  m[5],  m[6],  m[7],
        m[8],  m[9],  m[10], m[11],
        m[12], m[13], m[14], m[15]
    };

endmodule

/*
b0 ​​= (2⋅a0​) ⊕ (3⋅a1​) ⊕ a2 ​⊕ a3
​b1 ​= a0 ​⊕ (2⋅a1​) ⊕ (3⋅a2​) ⊕ a3
​b2 ​= a0​ ⊕ a1 ​⊕ (2⋅a2​) ⊕ (3⋅a3​)
​b3 = (3⋅a0​) ⊕ a1 ​⊕ a2 ​⊕ (2⋅a3​)​


*/