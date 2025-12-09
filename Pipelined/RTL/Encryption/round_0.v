module round_0 #(parameter BLOCK_LENGTH = 128)
(
    input                         clk,
    input                         rst,  
    input      [BLOCK_LENGTH-1:0] IN,
    input      [BLOCK_LENGTH-1:0] KEY,
    input                         enable, //to turn on/off the round
    output reg                    next_round_enable, // to move it to the next round
    output reg [BLOCK_LENGTH-1:0] OUT
);

wire [127:0] xor_out;

reg current_round_enable;

key_add xor_with_k0 (.IN(IN), .KEY(KEY), .OUT(xor_out)); // first step



always@(posedge clk or negedge rst)
begin

        if(!rst)
        begin
            OUT <= 128'b0;
            next_round_enable <= 0;
        end

        else
        begin
            next_round_enable <= enable;

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