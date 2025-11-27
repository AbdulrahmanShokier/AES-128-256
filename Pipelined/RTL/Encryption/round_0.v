module round_0 #(parameter BLOCK_LENGTH = 128)
(
    input                         clk,
    input                         rst,  
    input      [128-1:0] IN,
    input      [128-1:0] KEY,
    output reg [128-1:0] OUT
);

wire [127:0] xor_out;

key_add xor_with_k0 (.IN(IN), .KEY(KEY), .OUT(xor_out)); // first step

always@(posedge clk or negedge rst)
begin

    if(!rst)
    begin
        OUT <= 128'b0;
    end

    else
    begin
        OUT <= xor_out;
    end
    
end





endmodule