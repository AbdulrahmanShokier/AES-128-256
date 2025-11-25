module InvShiftRows  #(parameter BLOCK_LENGTH = 128)
(

    input wire  [BLOCK_LENGTH-1:0]  IN,
    output wire  [BLOCK_LENGTH-1:0]  OUT
);
	

    wire [7:0] s [0:15];
    assign {s[0], s[1], s[2], s[3],
            s[4], s[5], s[6], s[7],
            s[8], s[9], s[10], s[11],
            s[12], s[13], s[14], s[15]} = IN ;

    assign OUT = {
        s[0],  s[13], s[10], s[7],
        s[4],  s[1],  s[14], s[11],
        s[8],  s[5],  s[2],  s[15],
        s[12], s[9],  s[6],  s[3]
    };


endmodule

