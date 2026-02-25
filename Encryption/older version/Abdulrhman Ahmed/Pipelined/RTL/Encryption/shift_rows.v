
module shift_rows #(parameter BLOCK_LENGTH = 128)
(
    input wire  [BLOCK_LENGTH-1:0] IN,
    output wire [BLOCK_LENGTH-1:0] OUT
);

    // 16-long array with 8-bit (to slice 128-bit vector IN)
    wire [7:0] bytes [0:15];

    assign {bytes[0],  bytes[1],  bytes[2],  bytes[3],
            bytes[4],  bytes[5],  bytes[6],  bytes[7],
            bytes[8],  bytes[9],  bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]} = IN;

    // Perform AES ShiftRows
    assign OUT = {
        // Column 0
        bytes[0],  bytes[5],  bytes[10], bytes[15],  
        // Column 1
        bytes[4],  bytes[9],  bytes[14], bytes[3],
        // Column 2
        bytes[8],  bytes[13], bytes[2],  bytes[7],
        // Column 3
        bytes[12], bytes[1],  bytes[6],  bytes[11]
    };

endmodule
