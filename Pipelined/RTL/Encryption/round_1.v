module round_1 #(parameter BLOCK_LENGTH = 128)
(
    input                         clk,
    input                         rst,  
    input      [BLOCK_LENGTH-1:0] IN,
    input      [BLOCK_LENGTH-1:0] KEY,
    input      [BLOCK_LENGTH-1:0] KEY1,
    output reg [BLOCK_LENGTH-1:0] OUT
);

wire [127:0] xor_out1;
wire [127:0] sub_out;
wire [127:0] shft_out;
wire [127:0] mix_out;
wire [127:0] xor_out2;



key_add     xor_with_k0      (.IN(IN), .KEY(KEY), .OUT(xor_out1)); // first step

sub_bytes   sub_1            (.IN(xor_out1), .OUT(sub_out));

shift_rows  shft_1           (.IN(sub_out), .OUT(shft_out));

mix_columns mix_1            (.IN(shft_out), .OUT(mix_out));

key_add     xor_with_k1      (.IN(mix_out), .KEY(KEY1), .OUT(xor_out2)); 


always@(posedge clk)
begin

        if(!rst)
        begin
            OUT <= 128'b0;
        end

        else
        OUT <= xor_out2;

end


endmodule