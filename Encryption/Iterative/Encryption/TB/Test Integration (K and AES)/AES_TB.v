`timescale 1us/1us 

module AES_TB (); 

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

integer i_case; 

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
	
	DataText(); 		// input data for assignment and output data for check 
	//$readmemb("RoundKeys.txt", Round_Keys_Arr);
	
	reset();
	#(5*CLK_PER)
	
	/* the operation */ 
	for(i_case=0; i_case<No_Of_TestCases; i_case=i_case+1)
	 begin 
		do_oper(i_case); 
		check_out(i_case);		
	 end 
	 
	 
	 
	#(2*CLK_PER); 
	$stop;
end 




/////////////////////////////////////////////////
/////////////////// Tasks ///////////////////////
/////////////////////////////////////////////////

			/* input and output data task */ 
task DataText; 					 
 begin 
 
  Plain_text_Arr[0]   = 128'h3243F6A8885A308D313198A2E0370734; 
  Plain_text_Arr[1]   = 128'h1134F6A8885A308D313123A2E0370734;
  Plain_text_Arr[2]   = 128'h12122A32885A128D311611A21252AAFE;
  Plain_text_Arr[3]   = 128'hA266F6BF885AFF8D311619A2E0661522;
  Plain_text_Arr[4]   = 128'hCC662A32885A558D311619A2E052F2AA;
  
  Cipher_text_Arr[0]  = 128'h89ED5E6A05CA76338135085FE21C40BD;  
  Cipher_text_Arr[1]  = 128'h1C1D90B2FC352117926F5A4E62D9534B;							
  Cipher_text_Arr[2]  = 128'h4D84EA4245FF5C3419F8A18F6C3A6C26;							
  Cipher_text_Arr[3]  = 128'h391C2820A4ABE415F4B6458EB1A9A131;							
  Cipher_text_Arr[4]  = 128'h7FA47099DEBA4AE4F53671A9977280E0;							
  
  Keys_Arr[0]  	 	= 128'h000102030405060708090a0b0c0d0e0f;

 end
endtask

	/* reset task */ 
task reset; 
 begin 
  RST_tb = 1'b1; 
  CLK_tb = 1'b0; 
  
  #CLK_PER; 
  RST_tb = 1'b0; 
  #CLK_PER; 
  RST_tb = 1'b1;
  
 end 
endtask 

	/* inject the inputs and start the operaiton */ 
task do_oper;
 input [5:0] i;  
 begin 
  PT_tb = Plain_text_Arr[i]; 
  M_KEY_tb = Keys_Arr[0]; 		// you can chage it with more keys and more outputs coresspondant 
  En_tb = 1'b1; 
  #(1*CLK_PER);
  En_tb = 1'b0;
 end 
endtask

	/* check the output data: cipher text */ 
task check_out;
 input [5:0] i; 
 begin 
  @(posedge Valid_tb)
  #(CLK_PER/2)
  if(CT_tb == Cipher_text_Arr[i])
  	$display("TEST CASE %d is PASSED", i+1); 
  else 
    $display("TEST CASE %d is FAILED", i+1); 
 end
endtask 

/////////////////////////////////////////////////
///////////////// Clock Generator ///////////////
/////////////////////////////////////////////////

always #(CLK_PER/2) CLK_tb = ~CLK_tb; 

/////////////////////////////////////////////////
////////////// DUT Instantiations ///////////////
/////////////////////////////////////////////////

AES_Top DUT
(
.CLK_top(CLK_tb),
.RST_top(RST_tb), 
.En_top(En_tb),
.PT_top(PT_tb), 
.M_KEY_top(M_KEY_tb), 
.CT_top(CT_tb),
.Valid_top(Valid_tb)
); 



endmodule 