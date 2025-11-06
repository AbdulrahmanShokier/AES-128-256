
module AES_ENC_TOP #(parameter BLOCK_LENGTH = 128, parameter KEY_LENGTH = 128)
(
input wire  					CLK_top,
input wire  					RST_top, 
input wire  					AES_En_top,	
input wire  [BLOCK_LENGTH-1:0] 	PT_top, 
input wire  [KEY_LENGTH-1:0]   	KEY_top, 
output wire [BLOCK_LENGTH-1:0]  CT_top,
output wire 					Valid_top
); 


/* internal connections */ 
wire [KEY_LENGTH-1:0] Round_Key_top; 
wire 				  KEn_top; 


AES_Encryption #(.BLOCK_LENGTH(BLOCK_LENGTH)) U_AES_ENC
(
.CLK(CLK_top),
.RST(RST_top), 
.En(AES_En_top),	
.PT(PT_top), 
.M_KEY(KEY_top),
.K_En(KEn_top),
.K_i(Round_Key_top), 
.PT_i(CT_top),
.Valid(Valid_top)
); 


Key_Schedular #(.KEY_LENGTH(KEY_LENGTH)) U_KeySchedular(
.CLK(CLK_top),
.RST(RST_top), 
.M_KEY(KEY_top), 
.AES_En(AES_En_top),		
.K_En(KEn_top), 		
.subKey_curr(Round_Key_top)
); 







endmodule 