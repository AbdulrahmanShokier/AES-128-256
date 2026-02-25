module rounds_9_to_2_dec #(parameter BLOCK_LENGTH = 128)
(
    input                         clk,
    input                         rst,  
    input      [BLOCK_LENGTH-1:0] IN,
    input      [BLOCK_LENGTH-1:0] KEY,
    output reg [BLOCK_LENGTH-1:0] OUT
);



wire [127:0] sub_out;
wire [127:0] shft_out;
wire [127:0] mix_out;
wire [127:0] xor_out;


key_add         xor_with_k9_to_2 (.IN(IN), .KEY(KEY), .OUT(xor_out)); 

InvMixColumns   mix_9_to_2       (.IN(xor_out), .OUT(mix_out));

InvShiftRows    shft_9_to_2      (.IN(mix_out), .OUT(shft_out));

InvSubBytes     sub_9_to_2       (.IN(shft_out), .OUT(sub_out));


always@(posedge clk)
begin

        if(!rst)
        begin
            OUT <= 128'b0;
        end

        else
        OUT <= sub_out;

end



endmodule