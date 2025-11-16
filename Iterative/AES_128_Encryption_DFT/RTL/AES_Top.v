
module AES_Top #(parameter BLOCK_LENGTH = 128, KEY_LENGTH = 128)
(
input wire 						CLK_top,
input wire 						RST_top, 
input wire 						En_top,	
input wire  [BLOCK_LENGTH-1:0] 	PT_top, 
input wire  [KEY_LENGTH-1:0] 	M_KEY_top,
output wire [BLOCK_LENGTH-1:0] 	CT_top,
output wire 					Valid_top 
);


wire  [KEY_LENGTH-1:0] 		subKey_top;


AES_Encryption AES_Encryption_U0(
.CLK(CLK_top),
.RST(RST_top), 
.En(En_top),	
.PT(PT_top),
.M_Key(M_KEY_top), 
.K_i(subKey_top), 
.CT(CT_top),	
.Valid(Valid_top)
);

Key_Schedular Key_Schedular_U0(
.CLK(CLK_top), 
.RST(RST_top), 
.M_KEY(M_KEY_top), 		
.En(En_top), 	
.subKey_curr(subKey_top)
);




endmodule