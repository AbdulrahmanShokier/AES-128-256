module inverse_mix_columns (
    input  [127:0] resultant_state_array,
    output [127:0] inverse_mixed_state_array
);

    // Helper function: xtime (multiply by 2 in GF(2^8))
    function [7:0] xtime;
        input [7:0] a;
        begin
            if (a[7])
                xtime = (a << 1) ^ 8'h1B; // reduction by AES polynomial
            else
                xtime = a << 1;
        end
    endfunction

    // Multiply by 9
    function [7:0] mult_by_09;
        input [7:0] a;
        reg [7:0] a2, a4, a8;
        begin
            a2 = xtime(a);
            a4 = xtime(a2);
            a8 = xtime(a4);
            mult_by_09 = a8 ^ a;
        end
    endfunction

    // Multiply by 0B (11)
    function [7:0] mult_by_0B;
        input [7:0] a;
        reg [7:0] a2, a4, a8;
        begin
            a2 = xtime(a);
            a4 = xtime(a2);
            a8 = xtime(a4);
            mult_by_0B = a8 ^ a2 ^ a;
        end
    endfunction

    // Multiply by 0D (13)
    function [7:0] mult_by_0D;
        input [7:0] a;
        reg [7:0] a2, a4, a8;
        begin
            a2 = xtime(a);
            a4 = xtime(a2);
            a8 = xtime(a4);
            mult_by_0D = a8 ^ a4 ^ a;
        end
    endfunction

    // Multiply by 0E (14)
    function [7:0] mult_by_0E;
        input [7:0] a;
        reg [7:0] a2, a4, a8;
        begin
            a2 = xtime(a);
            a4 = xtime(a2);
            a8 = xtime(a4);
            mult_by_0E = a8 ^ a4 ^ a2;
        end
    endfunction

    // Break input into bytes (column-major)
    wire [7:0] s [0:15];
    assign { s[0], s[1], s[2], s[3],
             s[4], s[5], s[6], s[7],
             s[8], s[9], s[10], s[11],
             s[12], s[13], s[14], s[15] } = resultant_state_array;

    // Perform inverse MixColumns on each column
    wire [7:0] c0 [0:3], c1 [0:3], c2 [0:3], c3 [0:3];

    // Column 0
    assign c0[0] = mult_by_0E(s[0]) ^ mult_by_0B(s[1]) ^ mult_by_0D(s[2]) ^ mult_by_09(s[3]);
    assign c0[1] = mult_by_09(s[0]) ^ mult_by_0E(s[1]) ^ mult_by_0B(s[2]) ^ mult_by_0D(s[3]);
    assign c0[2] = mult_by_0D(s[0]) ^ mult_by_09(s[1]) ^ mult_by_0E(s[2]) ^ mult_by_0B(s[3]);
    assign c0[3] = mult_by_0B(s[0]) ^ mult_by_0D(s[1]) ^ mult_by_09(s[2]) ^ mult_by_0E(s[3]);

    // Column 1
    assign c1[0] = mult_by_0E(s[4]) ^ mult_by_0B(s[5]) ^ mult_by_0D(s[6]) ^ mult_by_09(s[7]);
    assign c1[1] = mult_by_09(s[4]) ^ mult_by_0E(s[5]) ^ mult_by_0B(s[6]) ^ mult_by_0D(s[7]);
    assign c1[2] = mult_by_0D(s[4]) ^ mult_by_09(s[5]) ^ mult_by_0E(s[6]) ^ mult_by_0B(s[7]);
    assign c1[3] = mult_by_0B(s[4]) ^ mult_by_0D(s[5]) ^ mult_by_09(s[6]) ^ mult_by_0E(s[7]);

    // Column 2
    assign c2[0] = mult_by_0E(s[8]) ^ mult_by_0B(s[9]) ^ mult_by_0D(s[10]) ^ mult_by_09(s[11]);
    assign c2[1] = mult_by_09(s[8]) ^ mult_by_0E(s[9]) ^ mult_by_0B(s[10]) ^ mult_by_0D(s[11]);
    assign c2[2] = mult_by_0D(s[8]) ^ mult_by_09(s[9]) ^ mult_by_0E(s[10]) ^ mult_by_0B(s[11]);
    assign c2[3] = mult_by_0B(s[8]) ^ mult_by_0D(s[9]) ^ mult_by_09(s[10]) ^ mult_by_0E(s[11]);

    // Column 3
    assign c3[0] = mult_by_0E(s[12]) ^ mult_by_0B(s[13]) ^ mult_by_0D(s[14]) ^ mult_by_09(s[15]);
    assign c3[1] = mult_by_09(s[12]) ^ mult_by_0E(s[13]) ^ mult_by_0B(s[14]) ^ mult_by_0D(s[15]);
    assign c3[2] = mult_by_0D(s[12]) ^ mult_by_09(s[13]) ^ mult_by_0E(s[14]) ^ mult_by_0B(s[15]);
    assign c3[3] = mult_by_0B(s[12]) ^ mult_by_0D(s[13]) ^ mult_by_09(s[14]) ^ mult_by_0E(s[15]);

    // Combine all columns back into state_out (column-major order)
    assign inverse_mixed_state_array = {c0[0], c0[1], c0[2], c0[3],
                                        c1[0], c1[1], c1[2], c1[3],
                                        c2[0], c2[1], c2[2], c2[3],
                                        c3[0], c3[1], c3[2], c3[3]};

endmodule
