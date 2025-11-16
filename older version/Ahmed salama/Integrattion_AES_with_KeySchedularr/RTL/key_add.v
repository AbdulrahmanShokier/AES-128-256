
module key_add #(parameter BLOCK_LENGTH = 128)
(
	input wire 						CLK,
	input wire 						RST,
    input wire  [BLOCK_LENGTH-1:0] 	IN,
    input wire  [BLOCK_LENGTH-1:0] 	KEY,
    output reg  [BLOCK_LENGTH-1:0] 	OUT
);

always @(posedge CLK or negedge RST)
begin 
 if(!RST)
	OUT <= 128'b0; 
 else 				// if(En)
	OUT <= IN ^ KEY;
end 


endmodule