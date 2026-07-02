
module bpskDecision
#(
	parameter DATA_WIDTH = 16
)

(
	input wire 							clk,
	input wire 							rst,

	input wire signed [DATA_WIDTH-1:0]  In,			// Input sample
	input wire 							valid_in,
	
	output reg 							Out,			// Output bit 
	output reg 							Out_vld 	// pypass valid_in for Rb rate (1/4 fs)
);

	reg Out_c; 
	
	/* latch bit out */ 
	always@(posedge clk)
	begin 
	 if(!rst)
		Out <= 'd0; 
	 else if(valid_in)
		Out <= Out_c; 
	end 
	
	/* decision */ 
	always@(*)
	begin 
	 if(In > 0)
		Out_c = 'b0; 
	 else 
		Out_c = 'b1; 
	end 
	

	/* paypass the valid signal (for Rb rate domain) */ 
	always@(posedge clk )
	begin 
		Out_vld <= valid_in; 
	end 







endmodule