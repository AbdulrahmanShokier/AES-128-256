module round_10_dec #(parameter BLOCK_LENGTH = 128)
(
    input                         clk,
    input                         rst,  
    input      [BLOCK_LENGTH-1:0] IN,
    input      [BLOCK_LENGTH-1:0] KEY,
    input                         enable, //to turn on/off the round
    output reg [BLOCK_LENGTH-1:0] OUT
);



wire [127:0] sub_out;
wire [127:0] shft_out;
wire [127:0] xor_out;


key_add         xor_with_k10 (.IN(IN), .KEY(KEY), .OUT(xor_out)); 

InvShiftRows    shft_10      (.IN(xor_out), .OUT(shft_out));

InvSubBytes     sub_10       (.IN(shft_out), .OUT(sub_out));



always@(posedge clk or negedge rst)
begin

        if(!rst)
        begin
            OUT <= 128'b0;
        end

        else
        begin
            if(enable)
            begin   
            OUT <= sub_out;
            end 
            
            else 
            begin
            OUT <= 128'b0;
            end
        end
end





endmodule