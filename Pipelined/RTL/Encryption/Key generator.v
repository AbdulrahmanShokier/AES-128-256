module key_generator #(parameter BLOCK_LENGTH = 128)
(
    input      [BLOCK_LENGTH-1:0] key,
    input      [7 : 0] round_number,
    input      clk,
    input      rst,
    input      valid,
    output reg [BLOCK_LENGTH-1:0] sub_key
);

wire [31:0] w0, w1, w2, w3;
wire [31:0] g_out;
wire [31:0] w4, w5, w6, w7;

wire [BLOCK_LENGTH-1:0] round_key;

assign w0 = key[127:96];
assign w1 = key[95:64];
assign w2 = key[63:32];
assign w3 = key[31:0];

g_function g_func (.word_3(w3), .round_number(round_number), .word_3_substituted(g_out));

assign w4 = w0 ^ g_out;
assign w5 = w1 ^ w4;
assign w6 = w2 ^ w5;
assign w7 = w3 ^ w6;

assign round_key = {w4, w5, w6, w7};




always@(rst or valid)
begin

    if(!rst)
    begin
        sub_key <= 128'b0;
    end
    if(valid)     // if valid signal arrived get out the next key
    begin
        
        if (round_number == 8'h0)
        begin
            sub_key <= key;
        end

        else
        begin
            sub_key <= round_key;
        end
    end

    else          // keep the current key  
    begin
        sub_key <= sub_key;
    end
    
end

endmodule