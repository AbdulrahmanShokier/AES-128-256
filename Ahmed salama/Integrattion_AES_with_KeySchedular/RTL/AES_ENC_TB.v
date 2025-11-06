`timescale 1us/1us 

module AES_ENC_TB (); 

/////////////////////////////////////////////////
/////////////////// Parameters //////////////////
/////////////////////////////////////////////////

parameter KEY_LENGTH  = 128; 
parameter BLOCK_LENGTH = 128; 
parameter No_Of_Rounds = 10; 
parameter CLK_PER = 10; 

parameter No_Of_TestCases = 5; 


/////////////////////////////////////////////////
//////////////// DUT Signals ////////////////////
/////////////////////////////////////////////////

reg 						CLK_tb;
reg 						RST_tb; 
reg 						En_tb;	
reg  	[BLOCK_LENGTH-1:0] 	PT_tb; 
reg  	[KEY_LENGTH-1:0] 	M_KEY_tb; 
wire  	[BLOCK_LENGTH-1:0] 	CT_tb;
wire 						Valid_tb;
 
/////////////////////////////////////////////////
//////////////// Loops Variables ////////////////
/////////////////////////////////////////////////

integer i_round; 

/////////////////////////////////////////////////
////////////////// Memories /////////////////////
/////////////////////////////////////////////////

reg [KEY_LENGTH-1:0]   Keys_Arr  		[No_Of_TestCases-1:0]; 		
reg [BLOCK_LENGTH-1:0] Plain_text_Arr   [No_Of_TestCases-1:0]; 		// original plain text (data blocks)
reg [BLOCK_LENGTH-1:0] Cipher_text_Arr  [No_Of_TestCases-1:0]; 		// final cipher text  

/////////////////////////////////////////////////
//////////////// Initial block //////////////////
/////////////////////////////////////////////////

initial 
begin 
	$dumpfile("AES_ENC.vcd") ;       
	$dumpvars; 
	
	Plain_text_Arr[0]   = 128'h3243F6A8885A308D313198A2E0370734; 
	Cipher_text_Arr[0]  = 128'h89ED5E6A05CA76338135085FE21C40BD;  
	Keys_Arr[0]  	 	= 128'h000102030405060708090a0b0c0d0e0f;

	//$readmemb("RoundKeys.txt", Round_Keys_Arr);
	
	
	RST_tb = 1'b1; 
	CLK_tb = 1'b0; 
	
	#CLK_PER; 
	RST_tb = 1'b0; 
	#CLK_PER; 
	RST_tb = 1'b1;
	#(5*CLK_PER)
	
	PT_tb = Plain_text_Arr[0]; 
	M_KEY_tb = Keys_Arr[0]; 
	En_tb = 1'b1; 
	#(1*CLK_PER);
	
	En_tb = 1'b0;
	
	
	@(posedge Valid_tb)
	#(CLK_PER/2)
	if(CT_tb == Cipher_text_Arr[0])
		$display("TEST CASE 1 is PASSED"); 
	
	#(2*CLK_PER); 
	$stop;
end 




/////////////////////////////////////////////////
/////////////////// Tasks ///////////////////////
/////////////////////////////////////////////////




/////////////////////////////////////////////////
///////////////// Clock Generator ///////////////
/////////////////////////////////////////////////

always #(CLK_PER/2) CLK_tb = ~CLK_tb; 

/////////////////////////////////////////////////
////////////// DUT Instantiations ///////////////
/////////////////////////////////////////////////

AES_ENC_TOP DUT
(
.CLK_top(CLK_tb),
.RST_top(RST_tb), 
.AES_En_top(En_tb),
.PT_top(PT_tb), 
.KEY_top(M_KEY_tb), 
.CT_top(CT_tb),
.Valid_top(Valid_tb)
); 



endmodule 