module round_0_dec #(parameter BLOCK_LENGTH = 128)
(
    input                         clk,
    input                         rst,  
    input      [BLOCK_LENGTH-1:0] IN,
    input      [BLOCK_LENGTH-1:0] KEY,
    input                         enable, //to turn on/off the round
    output reg [BLOCK_LENGTH-1:0] OUT
);

wire [127:0] xor_out;

key_add xor_with_k0 (.IN(IN), .KEY(KEY), .OUT(xor_out)); // first step



always@(posedge clk)
begin

        if(!rst)
        begin
            OUT <= 128'b0;
        end

        else
        begin
            if(enable)
            begin   
            OUT <= xor_out;
            end 
            
            else 
            begin
            OUT <= 128'b0;
            end
        end
end


endmodule