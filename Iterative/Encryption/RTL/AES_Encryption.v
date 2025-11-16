
module AES_Encryption #(parameter BLOCK_LENGTH = 128)
(
input wire 						CLK,
input wire 						RST, 
input wire 						En,			// Enabled with FSM (1 cycle later after outer En)
input wire  [BLOCK_LENGTH-1:0] 	PT, 		// the original plain text
input wire  [BLOCK_LENGTH-1:0] 	M_Key, 		// Main Key is gotten from outside not from the key schedular
input wire  [BLOCK_LENGTH-1:0] 	K_i, 		// RoundKey (Ki)
output wire [BLOCK_LENGTH-1:0]  CT,			// Cipher text (final output) 
output reg 						Valid		// inform the outside world that the CT port has valid data
); 

reg  						En_AES; 
reg  [BLOCK_LENGTH-1:0] 	PT_i;		// Plain text of round i, after round 10 it's the output (11th cycle) 

wire [BLOCK_LENGTH-1:0] PT0_KAdd;
wire [BLOCK_LENGTH-1:0] subByteOut_i; 
wire [BLOCK_LENGTH-1:0] shiftRowOut_i; 
wire [BLOCK_LENGTH-1:0] mixColOut_i;
wire [BLOCK_LENGTH-1:0] KAddIn_i;		// may be it's from mixCol (round_i) or shift rows (round 10)
wire [BLOCK_LENGTH-1:0] CT_i; 


wire SEL_PT, SEL_KAdd, SEL_End_Rounds, SEL_Last_R; 
reg Op_Flag; 
reg  [3:0] Round_Count; 	// #log2(no. of Rounds) -- may be add 2 parameters 
								// modif: extended for other key lenghts: 128, 196,256


key_add KA_U0 (.IN(PT), .KEY(M_Key), .OUT(PT0_KAdd));			// Ki is K0 before first round 
			
			/* iterative logic */ 
sub_bytes SB_U0(.IN(PT_i), .OUT(subByteOut_i));

shift_rows SR_U0(.IN(subByteOut_i), .OUT(shiftRowOut_i));

mix_columns MX_U0(.IN(shiftRowOut_i), .OUT(mixColOut_i)); 
 
MUX2x1_128 MUX_KAdd (.IN1(mixColOut_i), .IN2(shiftRowOut_i), .SEL(SEL_KAdd), .OUT(KAddIn_i));

key_add  KA_U1 (.IN(KAddIn_i), .KEY(K_i), .OUT(CT_i));
			
			/*********************/ 
assign CT = PT_i;					// output 


		/* En_AES logic - late the En one cycle to let the subkey prepared after the common 'En'*/
always@(posedge CLK or negedge RST)
begin 
 if(!RST)
	En_AES <= 1'b0; 
 else if(En) 
	En_AES <= 1'b1; 
 else 
	En_AES <= 1'b0; 
end 

			/* PT_i logic */ 
always@(posedge CLK or negedge RST)
begin 

 if(!RST)
	PT_i <= 128'b0; 
	
 else if (SEL_PT)			// SEL_PT is one only with "En at the beginning" 
	PT_i <= PT0_KAdd;

	/* optional */ 
 else if (SEL_End_Rounds) 	// optional (to maintain CT one more cycle )
  begin 
	PT_i <= PT_i; 			// end of op 
  end 
	/*******************/ 
  
 else if(Op_Flag)						// for rounds 1:9 
	PT_i <= CT_i;
	
end

		/* Valid signal logic */ 
always@(posedge CLK or negedge RST)
begin 
 if(!RST)
	Valid <= 'b0; 
 else if (SEL_Last_R)
	Valid = 1'b1; 
 else 
	Valid = 1'b0; 
end 



assign SEL_PT = En_AES && (Round_Count == 'd0); 		// sure? 
assign SEL_KAdd = (Round_Count == 'd10); 	// sure? 
assign SEL_Last_R = SEL_KAdd;					 // sure? 
assign SEL_End_Rounds = (Round_Count == 'd11);



		/* 5-bit Round Counter logic */ 
always@(posedge CLK or negedge RST)
begin

 if(!RST)
  begin 
	Round_Count <= 'd0; 
	Op_Flag = 1'b0; 
  end 
	
 else if(En_AES && Round_Count == 'd0) // the second condition (==0) is to filter out any unexpected En (through the oper)
  begin
	Round_Count <= 'd1; 
	Op_Flag <= 1'b1; 				 // "Operatoin_Flag": it's for continuity of the counter with only one 'En' pulse 
  end
  
 else if (Round_Count == 'd11)
  begin 
	Op_Flag <= 1'b0; 
	Round_Count <= 'b0;
  end 	
  
 else if(Op_Flag)
	Round_Count <= Round_Count + 'b1;
	 
end  






endmodule