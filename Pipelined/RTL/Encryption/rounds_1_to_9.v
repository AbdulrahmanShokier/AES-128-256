module rounds_1_to_9 #(parameter BLOCK_LENGTH = 128)
(
    input                         clk,
    input                         rst,  
    input      [BLOCK_LENGTH-1:0] IN,
    input      [BLOCK_LENGTH-1:0] KEY,
    input                         enable, //to turn on/off the round
    output reg                    next_round_enable, // to move it to the next round
    output reg [BLOCK_LENGTH-1:0] OUT
);



wire [127:0] sub_out;
wire [127:0] shft_out;
wire [127:0] mix_out;
wire [127:0] xor_out;

reg current_round_enable;


sub_bytes   sub_1_to_9       (.IN(IN), .OUT(sub_out));

shift_rows  shft_1_to_9      (.IN(sub_out), .OUT(shft_out));

mix_columns mix_1_to_9       (.IN(shft_out), .OUT(mix_out));

key_add     xor_with_k1_to_9 (.IN(mix_out), .KEY(KEY), .OUT(xor_out)); 






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