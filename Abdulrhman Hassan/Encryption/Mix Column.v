module mix_columns (
    input  [127:0] shifted_state_array,
    output [127:0] mixed_state_array
);

    // Split input into 16 bytes (column-major order)
    wire [7:0] s [0:15];
    assign {
        s[0],  s[4],  s[8],  s[12],
        s[1],  s[5],  s[9],  s[13],
        s[2],  s[6],  s[10], s[14],
        s[3],  s[7],  s[11], s[15]
    } = shifted_state_array;

    // GF(2^8) multiplication functions
    function [7:0] xtime(input [7:0] x);
        begin
            xtime = (x[7]) ? ((x << 1) ^ 8'h1b) : (x << 1);
        end
    endfunction

    function [7:0] mul2(input [7:0] x);
        mul2 = xtime(x);
    endfunction

    function [7:0] mul3(input [7:0] x);
        mul3 = xtime(x) ^ x;
    endfunction

    // MixColumns transformation
    wire [7:0] m [0:15];

    // العمود 0
    assign m[0]  = mul2(s[0]) ^ mul3(s[1]) ^ s[2] ^ s[3];
    assign m[1]  = s[0] ^ mul2(s[1]) ^ mul3(s[2]) ^ s[3];
    assign m[2]  = s[0] ^ s[1] ^ mul2(s[2]) ^ mul3(s[3]);
    assign m[3]  = mul3(s[0]) ^ s[1] ^ s[2] ^ mul2(s[3]);

    // العمود 1
    assign m[4]  = mul2(s[4]) ^ mul3(s[5]) ^ s[6] ^ s[7];
    assign m[5]  = s[4] ^ mul2(s[5]) ^ mul3(s[6]) ^ s[7];
    assign m[6]  = s[4] ^ s[5] ^ mul2(s[6]) ^ mul3(s[7]);
    assign m[7]  = mul3(s[4]) ^ s[5] ^ s[6] ^ mul2(s[7]);

    // العمود 2
    assign m[8]  = mul2(s[8]) ^ mul3(s[9]) ^ s[10] ^ s[11];
    assign m[9]  = s[8] ^ mul2(s[9]) ^ mul3(s[10]) ^ s[11];
    assign m[10] = s[8] ^ s[9] ^ mul2(s[10]) ^ mul3(s[11]);
    assign m[11] = mul3(s[8]) ^ s[9] ^ s[10] ^ mul2(s[11]);

    // العمود 3
    assign m[12] = mul2(s[12]) ^ mul3(s[13]) ^ s[14] ^ s[15];
    assign m[13] = s[12] ^ mul2(s[13]) ^ mul3(s[14]) ^ s[15];
    assign m[14] = s[12] ^ s[13] ^ mul2(s[14]) ^ mul3(s[15]);
    assign m[15] = mul3(s[12]) ^ s[13] ^ s[14] ^ mul2(s[15]);

    // Reassemble output in the same column-major order
    assign mixed_state_array = {
        m[0],  m[4],  m[8],  m[12],
        m[1],  m[5],  m[9],  m[13],
        m[2],  m[6],  m[10], m[14],
        m[3],  m[7],  m[11], m[15]
    };

endmodule
//              /
//  working    /
//           \/
