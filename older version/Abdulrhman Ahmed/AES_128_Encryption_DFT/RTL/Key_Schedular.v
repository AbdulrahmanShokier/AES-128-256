
module Key_Schedular
#(parameter KEY_LENGTH = 128, 
		    KEY_WORD_LENGTH = 32,		// 128/4 (4 key words)
		    QUART_KW_LENGTH = 8 )		// 32/4 (Quarter of KW)

(
input wire 						RST, 
input wire 						CLK, 
input wire [KEY_LENGTH-1:0] 	M_KEY, 				// Main key
input wire 						En, 				// enable from outside block 
output reg [KEY_LENGTH-1:0] 	subKey_curr 		// subkey output 
); 


reg [KEY_LENGTH-1:0] subKey_next;
reg 				 Flag_op; 		// for operation continuity after one pulse En

/* note: W3 is the most right word in the round key */ 
wire  [KEY_WORD_LENGTH-1:0] W3_perm;			// W3 permutated through g-function 
wire [KEY_WORD_LENGTH-1:0] W3_S;	 		// W3 S_boxes output th. g-function 
wire [KEY_WORD_LENGTH-1:0] W3_g;			// the output of g-func of input: W3
reg  [3:0] 				   Round_Count; 	
reg  [QUART_KW_LENGTH-1:0] Round_Const; 	// it's made 8 to be as long as key_W/4 as inside the g-func 

//wire [KEY_WORD_LENGTH-1:0] test1,test2,test3,test4; 

		/* current subkey logic */ 
always@(posedge CLK, negedge RST)
begin

 if(!RST)
  begin 
	subKey_curr <= 128'b0; 			// k0 
  end 
  
 else if(En && Round_Count == 'd0) 
  begin 
	subKey_curr <= M_KEY; 	// other round key
  end 
  
 else if(Flag_op)
  begin 
	subKey_curr <= subKey_next; 
  end
  
end 





			/* Next subkey logic */ 
always@(*)
begin
 subKey_next[127:96]  =  subKey_curr[127:96]  ^ W3_g ; 						// mostLeftWord W[0]
 subKey_next[95: 64]  =  subKey_curr[95: 64]  ^ subKey_next[127:96] ; 		// for that we use 'blocking assing.' 
 subKey_next[63: 32]  =  subKey_curr[63: 32]  ^ subKey_next[95:64] 	;  
 subKey_next[31:  0]  =  subKey_curr[31:  0]  ^ subKey_next[63:32] 	; 
end 

 //assign test1 = subKey_curr[127:96]  ^ W3_g ; 
 //assign test2 = subKey_curr[95: 64]  ^ subKey_next[127:96] ;
 // .. for testing 
 

			/* g-function to get W3_g */ 
assign W3_perm = (subKey_curr[31:0] << 8) | {{24'b0},subKey_curr[31:24]};
 // OR :
 /* 
 W3_perm[31:24] = subKey_curr[23:16]; 
 W3_perm[23:16] = subKey_curr[15:8];
 W3_perm[15:8]  = subKey_curr[7:0]; 
 W3_perm[7:0]   = subKey_curr[31:24]; 
 */ 
 S_box S1( .in_byte(W3_perm[7:0]),   .out_byte(W3_S[7:0])   );
 S_box S2( .in_byte(W3_perm[15:8]),  .out_byte(W3_S[15:8])  );
 S_box S3( .in_byte(W3_perm[23:16]), .out_byte(W3_S[23:16]) );
 S_box S4( .in_byte(W3_perm[31:24]), .out_byte(W3_S[31:24]) );
 
 assign W3_g = {(W3_S[31:24] ^ Round_Const), W3_S[23:0]};


/* KeySchecdular Round Counter */ 
always@(posedge CLK or negedge RST)
begin 

 if(!RST)
  begin 
	Round_Count <= 4'd0; 
	Flag_op <= 1'b0;
  end 
  
 else if (En && Round_Count == 4'd0)
  begin 
	Round_Count <= 4'd1;
	Flag_op <= 1'b1; 
  end 
  
  else if(Round_Count == 'd11)
  begin 
	Round_Count <= 'b0; 	// for later operations
	Flag_op <= 'b0; 
  end 
  
 else if(Flag_op == 'b1)				// this condition is the operation condition (lowest priority)
	Round_Count <= Round_Count + 'd1; 
	
end 

/* Then generate Round Constant */ 
always@(*)
begin 
 case(Round_Count)
 4'd1:  Round_Const = 8'h1; 
 4'd2:  Round_Const = 8'h2; 
 4'd3:  Round_Const = 8'h4; 
 4'd4:  Round_Const = 8'h8; 
 4'd5:  Round_Const = 8'h10; 
 4'd6:  Round_Const = 8'h20; 
 4'd7:  Round_Const = 8'h40; 
 4'd8:  Round_Const = 8'h80; 
 4'd9:  Round_Const = 8'h1B; 
 4'd10: Round_Const = 8'h36; 
 default: Round_Const = 8'h0; 
 endcase
end 
/***************************************************/





endmodule 