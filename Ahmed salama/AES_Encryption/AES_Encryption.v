
module AES_Encryption #(parameter BLOCK_LENGTH = 128)
(
input wire 						CLK,
input wire 						RST, 
input wire 						KGen_En,	// needed, ha?
input wire  [BLOCK_LENGTH-1:0] 	PT, 		// the original plain text
input wire  [BLOCK_LENGTH-1:0] 	K_i, 		// RoundKey (Ki)
output reg  [BLOCK_LENGTH-1:0] 	CT_i,		// Cipher text of round i 
output reg 						Valid
); 

wire [BLOCK_LENGTH-1:0] PT_i; 
wire [BLOCK_LENGTH-1:0] subByteOut_i; 
wire [BLOCK_LENGTH-1:0] shiftRowOut_i; 
wire [BLOCK_LENGTH-1:0] mixColOut_i;
wire [BLOCK_LENGTH-1:0] KAddIn_i;
wire [BLOCK_LENGTH-1:0] KAddOut_i;

wire SEL_PT, SEL_KAdd; 
reg  [4:0] Round_Count; 	// #log2(no. of Rounds) -- may be add 2 parameters 
							// extended for other key lenghts: 128, 196,256

 
assign SEL_PT = Round_Count != 4'd1; 	// sure? 
assign SEL_KAdd = Round_Count != 4'd10; // sure? 

MUX2x1_128 MUX_PT_U0(.IN1(PT), .IN2(CT_i), SEL(SEL_PT), .OUT(PT_i)); 

sub_bytes SB_U0(.IN(PT_i), .OUT(subByteOut_i));

shift_rows SR_U0(.IN(subByteOut_i), OUT(shiftRowOut_i));

mix_columns MX_U0(.IN(shiftRowOut_i), .OUT(mixColOut_i)); 
 
MUX2x1_128 MUX_KAdd (.IN1(shiftRowOut_i), .IN2(mixColOut_i), SEL(SEL_KAdd), .OUT(KAddIn_i));

key_add KA_U0(.IN(KAddIn_i), .KEY(K_i), .OUT(KAddOut_i));


always@(posedge CLK or negedge RST)
begin 
 if(!RST)
	CT_i <= 128'b0; 
 else if 
	CT_i <= KAddOut_i;
end 

...












endmodule