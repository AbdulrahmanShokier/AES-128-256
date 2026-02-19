module rounds_2_to_9 #(parameter BLOCK_LENGTH = 128)
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


sub_bytes   sub_2_to_9       (.IN(IN), .OUT(sub_out));

shift_rows  shft_2_to_9      (.IN(sub_out), .OUT(shft_out));

mix_columns mix_2_to_9       (.IN(shft_out), .OUT(mix_out));

key_add     xor_with_k2_to_9 (.IN(mix_out), .KEY(KEY), .OUT(xor_out)); 






always@(posedge clk )
begin

        if(!rst)
        begin
            OUT <= 128'b0;
        end

        else
        OUT <= xor_out; 

end



endmodule