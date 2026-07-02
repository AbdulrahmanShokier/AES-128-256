`timescale 1us/1us

module Rx_bpsk_Top_tb();

//////////////// Parameters ////////////////////
parameter DATA_WIDTH  = 16;
parameter PREAMPLE_LENGTH = 255;
parameter NO_OFFSETS = 4;		// OSR = 4 
parameter CLK_PER 	  = 10; 
parameter Control_Length = 256;


//////////////// Memoreies //////////////////////
reg [DATA_WIDTH-1:0] Preamble_vector [PREAMPLE_LENGTH-1:0];
reg [DATA_WIDTH-1:0] MFIn_vector [2999:0]; 			// preamble+control samples (after upsampled + shaping)
																// 	= (16 + 255*4 +256*4 ) = 2060 + 20*4 (for 20-bit payload)		
																// + some delay for processing -> 2200 cycles 
/////////////// Integers ////////////////////////
integer i, f_out; 

//////////////// DUT Signals ////////////////////
reg 								clk_tb;
reg 								rst_tb;
reg signed [DATA_WIDTH-1:0]  		RxInBpsk_tb;	
reg signed [DATA_WIDTH-1:0] 		RxIn16pskI_tb;
reg signed [DATA_WIDTH-1:0] 		RxIn16pskQ_tb;

wire 	   [Control_Length-1:0] 	Control_register_tb;
wire 								Control_complete_tb;

//////////////// Initial block //////////////////
initial 
begin 
	$dumpfile(".vcd"); 
	$dumpvars;
	
 
	RxInBpsk_tb = 'd0; 			/* FATAL if forgetten */ 
		
	/* reset */ 
	clk_tb = 'b0; 
	rst_tb = 'b1; 
	#CLK_PER; 
	rst_tb = 1'b0; 
	#CLK_PER; 
	rst_tb = 1'b1; 
	
	
	/* Initialize MFIn_vector with zeroes initially */ 
	for(i=0; i<2999; i=i+1)
	 begin 
		MFIn_vector[i] = 'd0; 
	 end 
	 
	/* read the 2 preamble and samples vectors */ 
	//$readmemh("PreambleFixedVecotr.txt",Preamble_vector);
	$readmemh("MatchedF_TestInput.txt",MFIn_vector);
	
	#(50*CLK_PER);
	 
	
	for(i=0; i<2200; i=i+1)				// how many cycles needed? -> go to line 13 
	 begin 
		RxInBpsk_tb = MFIn_vector[i];
		#CLK_PER;
	
	 end
	 
	//#((9+2+3)*CLK_PER);							// 9-cycle latency of correlators, 2 cycels for comparisons, 3 for 3 successive peaks (candidates)
		
	 
	#(10*CLK_PER); 
	$stop; 

end 


/// Test block: get the control field detected ////
integer controlField_file;
initial begin
	controlField_file = $fopen("OutputControlField.txt", "w"); 	// to write out the control field detected 
		@(posedge Control_complete_tb)
			$fwrite(controlField_file, "%b\n", Control_register_tb);
			$fclose(controlField_file);
end


///////////////// Clock Generator ///////////////
always begin #(CLK_PER/2); clk_tb = ~clk_tb; end 


////////////// DUT Instantiation ///////////////
Rx_bpsk_Top DUT(
.clk(clk_tb),
.rst(rst_tb),
.RxInBpsk(RxInBpsk_tb),
.RxIn16pskI(RxIn16pskI_tb),
.RxIn16pskQ(RxIn16pskQ_tb),
.Control_register(Control_register_tb),
.Control_complete(Control_complete_tb)
); 



endmodule