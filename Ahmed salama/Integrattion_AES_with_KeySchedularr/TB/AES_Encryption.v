
module AES_Encryption #(parameter BLOCK_LENGTH = 128)
(
input wire 						CLK,
input wire 						RST, 
input wire 						En,			// Enabled with outer block 
input wire  [BLOCK_LENGTH-1:0] 	PT, 		// the original plain text
input wire  [BLOCK_LENGTH-1:0] 	M_KEY, 		// Main Key 
input wire  [BLOCK_LENGTH-1:0] 	K_i, 		// RoundKey (Ki)
output reg 						K_En, 		// hey KeyShedular, give me the key next cycle 
output reg  [BLOCK_LENGTH-1:0] 	PT_i,		// Plain text of round i, after round 10 it's the output (11th cycle) 
output reg 						Valid		// inform the outside world that the CT port has valid data
); 

wire [BLOCK_LENGTH-1:0] PT0_KAdd;
wire [BLOCK_LENGTH-1:0] subByteOut_i; 
wire [BLOCK_LENGTH-1:0] shiftRowOut_i; 
wire [BLOCK_LENGTH-1:0] mixColOut_i;
wire [BLOCK_LENGTH-1:0] KAddIn_i;		// may be it's from mixCol (round_i) or shift rows (round 10)
wire [BLOCK_LENGTH-1:0] CT_i; 


wire 		SEL_PT, SEL_KAdd, SEL_Final_CT; 
reg  		Op_Flag; 
reg   [5:0] Cycles_Count; 	
reg   [4:0] Round_Count; 	// #log2(no. of Rounds) -- may be add 2 parameters 
								// modif: extended for other key lenghts: 128, 196,256


key_add KA_U0 (.CLK(CLK), .RST(RST), .IN(PT), .KEY(M_KEY), .OUT(PT0_KAdd));			// Ki is K0 before first round 
			
			/* iterative logic */ 
sub_bytes SB_U0(.IN(PT_i), .OUT(subByteOut_i));

shift_rows SR_U0(.CLK(CLK), .RST(RST), .IN(subByteOut_i), .OUT(shiftRowOut_i));

mix_columns MX_U0(.IN(shiftRowOut_i), .OUT(mixColOut_i)); 
 
MUX2x1_128 MUX_KAdd (.IN1(mixColOut_i), .IN2(shiftRowOut_i), .SEL(SEL_KAdd), .OUT(KAddIn_i));

key_add  KA_U1 (.CLK(CLK), .RST(RST), .IN(KAddIn_i), .KEY(K_i), .OUT(CT_i));
			
			
			/* PT_i logic */ 
always@(posedge CLK or negedge RST)
begin 

 if(!RST)
	PT_i <= 128'b0; 
	
 else if (SEL_PT)			// SEL_PT is one only with "En at the beginning" 
	PT_i <= PT0_KAdd;

	/* optional */ 
 else if (SEL_Final_CT) 	// optional (to maintain CT one more cycle )
  begin 
	PT_i <= PT_i; 			// end of op 
  end 
	/*******************/ 
  
 else 						// for rounds 1:9 
	PT_i <= CT_i;
	
end

		/* Valid signal logic */ 
always@(posedge CLK or negedge RST)
begin 
 if(!RST)
	Valid <= 'b0; 
 else if (Cycles_Count == (5'd10*3 + 'd1))
	Valid = 1'b1; 
 else 
	Valid = 1'b0; 
end 


assign SEL_PT = (Cycles_Count == 5'd1); 	// sure? 
assign SEL_KAdd = (Round_Count == 5'd10); // sure? 
assign SEL_Final_CT = (Cycles_Count == (5'd11*3 - 'd1));


		
		/*10-round Round Counter logic */ 

always@(*)
begin
 case(Cycles_Count)
 6'd1 , 6'd2 , 6'd3 : Round_Count = 5'd1; 
 6'd4 , 6'd5 , 6'd6 : Round_Count = 5'd2; 
 6'd7 , 6'd8 , 6'd9 : Round_Count = 5'd3; 
 6'd10, 6'd11, 6'd12: Round_Count = 5'd4; 
 6'd13, 6'd14, 6'd15: Round_Count = 5'd5; 
 6'd16, 6'd17, 6'd18: Round_Count = 5'd6; 
 6'd19, 6'd20, 6'd21: Round_Count = 5'd7; 
 6'd22, 6'd23, 6'd24: Round_Count = 5'd8; 
 6'd25, 6'd26, 6'd27: Round_Count = 5'd9; 
 6'd28, 6'd29, 6'd30: Round_Count = 5'd10; 
 6'd31, 6'd32, 6'd33: Round_Count = 5'd11; 
 default: Round_Count = 5'd0;
 endcase  
end  	
		
always@(posedge CLK or negedge RST)
begin

 if(!RST)
	Cycles_Count <= 5'd0; 
	
 else if(En && (Cycles_Count == 5'd0)) // the second condition (==0) is to filter out any unexpected En (through the oper)
  begin
	Cycles_Count <= 5'd1; 
	Op_Flag <= 1'b1; 				 // "Operatoin_Flag": it's for continuity of the counter with only one 'En' pulse 
  end
  
 else if (Cycles_Count == (5'd11*3))
  begin 
	Op_Flag <= 1'b0; 
	Cycles_Count <= 5'b0;
  end 	
  
 else if(Op_Flag)
	Cycles_Count <= Cycles_Count + 5'b1;
	 
end  

/*******************************************/ 


	/* KEY Enable logic */ 

always @(posedge CLK or negedge RST)
begin
 if(!RST)
	K_En <= 1'b0; 
 else if(   Cycles_Count == 6'd1  | Cycles_Count == 6'd4  | Cycles_Count == 6'd7  | Cycles_Count == 6'd10
		  | Cycles_Count == 6'd13 | Cycles_Count == 6'd16 | Cycles_Count == 6'd19 | Cycles_Count == 6'd22
		  | Cycles_Count == 6'd25 | Cycles_Count == 6'd28
		 )
			K_En <= 1'b1; 
 else 
	K_En = 1'b0; 
end 
	
	
	
	



endmodule