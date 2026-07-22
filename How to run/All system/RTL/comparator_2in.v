
module comparator_2in
#(
	parameter DATA_WIDTH  = 16,   // input/output width
	parameter NO_OFFSETS  = 4    // = OSR 
	
)

(
	input wire 											clk_sample,
	input wire 											rst,
	input wire signed		[DATA_WIDTH-1:0] 			in1,
	input wire signed		[DATA_WIDTH-1:0] 			in2,
	output reg signed		[DATA_WIDTH-1:0] 			out
);

	
	wire [DATA_WIDTH-1:0]		  bigger;

	always@(posedge clk_sample )
	begin 
	 if(!rst)
	  begin 
		out <= 'd0; 
	  end 
	 else 
	  begin 
		out <= bigger ;
	  end 
	end 

	assign bigger = (in1>=in2)? in1:in2;






endmodule