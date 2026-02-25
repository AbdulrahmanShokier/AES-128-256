module Add_Round_Key 
(
    input              clk,
    input              asy_reset,
    input      [127:0] plain_text,
    input      [127:0] key,
    output     [127:0] resultant_state_array
);

always@(posedge clk or negedge asy_reset)
begin
    if(!asy_reset)
    begin
        resultant_state_array <= 128'h0;
    end

    else 
    begin
        resultant_state_array = plain_text ^ key;

    end
end


endmodule


