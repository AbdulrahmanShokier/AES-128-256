
module bufferDelay14
#(
	parameter DATA_WIDTH = 16,
	parameter NO_OFFSETS = 4,		// OSR = 4
	parameter FRAMEVALID_LATENCY = 14
)
(
	input wire 							clk,
	input wire 							rst,
	input wire signed [DATA_WIDTH-1:0]  in, 
	output reg signed [DATA_WIDTH-1:0]  out
);

	
	reg signed [DATA_WIDTH-1:0] buffer [FRAMEVALID_LATENCY-1:0]; 
	
	integer i; 
	always@(posedge clk )
	begin 
	 if(!rst)
	  begin 
		out <= 'd0; 
		for(i=0; i<FRAMEVALID_LATENCY; i=i+1)
			buffer[i] = 'd0; 
	  end 
	 else 
	  begin 
		buffer[0] <= in; 
		for(i=0; i<FRAMEVALID_LATENCY-1; i=i+1)
			buffer[i+1] <= buffer[i];
		out <= buffer[FRAMEVALID_LATENCY-1]; 
	  end 
		
	end 






endmodule