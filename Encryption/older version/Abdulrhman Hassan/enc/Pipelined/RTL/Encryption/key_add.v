
module key_add #(parameter BLOCK_LENGTH = 128)
(
    input wire  [BLOCK_LENGTH-1:0] IN,
    input wire  [BLOCK_LENGTH-1:0] KEY,
    output wire [BLOCK_LENGTH-1:0] OUT
);

assign OUT = IN ^ KEY;

endmodule