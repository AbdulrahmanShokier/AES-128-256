
	/* Compare with the threshold to find the global peak */ 
	/* based on that, flag the validFrame signal for starting of the frame */
	/* And control it, down it after frame length */ 

module comparator_threshld					// compare the local peak with the threshold until get a global peak
												// and compare between the candidates (for max global peak)
#(
	parameter DATA_WIDTH  = 16,   // input/output width
	parameter NO_OFFSETS  = 4,    // = OSR 
	parameter THRESHOLD =  'sd9988	// 70% * best peak (255*FIR_gain^2 in Q26), i.e., (70% * 5.984642662400000e+10)/2^22
	
)

(
	input wire 									clk_sample,
	input wire 									rst,
	input wire signed		[DATA_WIDTH-1:0] 	in,
	output reg 									ValidFrame
);

	wire 										ExceedTh_c;
	reg 										ExceedTh;		// Flag to announce that threshold is exceeded
	reg signed		[DATA_WIDTH-1:0] 			maxGlobalPeak;	// no need to make it an output
	wire signed 	[DATA_WIDTH-1:0]			max; 
	
 

	always@(posedge clk_sample)
	begin 
	 if(!rst) 
	  begin 
		maxGlobalPeak <= 'd0; 
		ExceedTh <='d0;
		ValidFrame <='b0; 
	  end
	 else if (ExceedTh && ExceedTh_c)	/* logic for successive peaks (get the maximum peak) */ 		
	  begin 								/* that's bigger than its previous and its next */ 
		maxGlobalPeak <= max; 					/* (2nd stage) */ 
		ExceedTh <= 'd1; 
	  end 
	 else if(ExceedTh_c)				/* logic for the first peak*/ 
	  begin 									/*  (1st stage) */ 
		maxGlobalPeak <= in ;
		ExceedTh <= 'd1; 
	  end
	 else if(ExceedTh)					/* no more peaks - now surely we have the best offset */ 
	  begin 									/* Last stage */ 
		ExceedTh <= 'b0; 
		ValidFrame <= 'b1;				//and now you should have the next sample with this valid edge
	  end 
	 else 
	  begin 									/* The default stage */ 
		ExceedTh <= 'd0;
		ValidFrame <= 'b0; 								
	  end 
	end 

	assign ExceedTh_c = (in >= THRESHOLD);  
	
	assign max = (maxGlobalPeak>=in)? maxGlobalPeak:in;
	
	
	




endmodule