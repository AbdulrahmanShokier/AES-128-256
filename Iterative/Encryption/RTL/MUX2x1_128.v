
module MUX2x1_128 #(parameter BLOCK_LENGTH = 128)
(
input wire  [BLOCK_LENGTH-1:0] IN1, 
input wire  [BLOCK_LENGTH-1:0] IN2,
input wire 					   SEL,
output reg [BLOCK_LENGTH-1:0] OUT
); 


always@(*)
begin
 if(!SEL)
	OUT = IN1; 
 else 
	OUT = IN2; 
end 



endmodule