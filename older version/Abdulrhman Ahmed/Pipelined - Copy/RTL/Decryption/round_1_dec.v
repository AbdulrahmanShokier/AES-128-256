module round_1_dec #(parameter BLOCK_LENGTH = 128)
(
    input                         clk,
    input                         rst,  
    input      [BLOCK_LENGTH-1:0] IN,
    input      [BLOCK_LENGTH-1:0] KEY1,
    input      [BLOCK_LENGTH-1:0] KEY0,
    output reg [BLOCK_LENGTH-1:0] OUT
);
    wire [127:0] xor_out9;
    wire [127:0] sub_out;
    wire [127:0] shft_out;
    wire [127:0] mix_out;
    wire [127:0] xor_out10;

    key_add         xor_with_k1  (.IN(IN), .KEY(KEY1), .OUT(xor_out9));
    InvMixColumns   mix_1        (.IN(xor_out9), .OUT(mix_out));
    InvShiftRows    shft_1       (.IN(mix_out), .OUT(shft_out));
    InvSubBytes     sub_1        (.clk(clk), .rst(rst), .IN(shft_out), .OUT(sub_out)); // Added clk/rst
    key_add         xor_with_k0  (.IN(sub_out), .KEY(KEY0), .OUT(xor_out10)); // first step

    always@(posedge clk)
    begin
        if(!rst) begin
            OUT <= 128'b0;
        end else begin
            OUT <= xor_out10;
        end
    end
endmodule