module round_10 #(parameter BLOCK_LENGTH = 128)
(
    input                         clk,
    input                         rst,  
    input      [128-1:0] IN,
    input      [128-1:0] KEY,
    output reg [128-1:0] OUT
);



wire [127:0] sub_out;
wire [127:0] shft_out;
wire [127:0] xor_out;



sub_bytes  sub_10       (.IN(IN), .OUT(sub_out));

shift_rows shft_10      (.IN(sub_out), .OUT(shft_out));

key_add    xor_with_k10 (.IN(shft_out), .KEY(KEY), .OUT(xor_out)); 



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