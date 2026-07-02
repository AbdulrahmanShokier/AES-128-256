

module Sampler
#(
    parameter DATA_WIDTH  = 16,   									// input/output width
	parameter OSR 		  = 4  										// Over smapling ratio = 4 samples/symbol	

)
(
	input wire 							clk_sample,
	input wire 							rst, 
	input wire signed [DATA_WIDTH-1:0]  data_in,
	output reg signed [DATA_WIDTH-1:0]  data_out0, 	// offset0: first sample (no offset)
	output reg signed [DATA_WIDTH-1:0]  data_out1,	// offset1: second sample 
	output reg signed [DATA_WIDTH-1:0]  data_out2,	// ..
	output reg signed [DATA_WIDTH-1:0]  data_out3,
	output reg		  [OSR-1:0] 		offset_vld
	
);
	
	
	/* Internal signals */ 
	reg [$clog2(OSR):0] 			Counter_SymbolWindow; 
	wire offset0,offset1,offset2,offset3; 	
	
	
	/* DownSampler */ 
	/* sample one out of 4 */ 
	always @(posedge clk_sample, negedge rst)
	begin 
	 if(!rst)
	  begin 
		data_out0 <= 'd0;
        data_out1 <= 'd0;
        data_out2 <= 'd0;
        data_out3 <= 'd0;
		offset_vld[OSR-1:0] <= 'd0;   
	  end 
	 if (offset0) begin 
		data_out0 <= data_in;
		offset_vld[OSR-1:0] <= 'd1; 	// 0001
		end 
	 if (offset1) begin 
		data_out1 <= data_in;
		offset_vld[OSR-1:0] <= 'd2; 	// 0010
		end 
	 if (offset2) begin 
		data_out2 <= data_in;
		offset_vld[OSR-1:0] <= 'd4; 	// 0100
		end 
	 if (offset3) begin 
		data_out3 <= data_in;
		offset_vld[OSR-1:0] <= 'd8; 	// 1000
		end 
	end
	/* ----------------------------------------------------------------------------*/ 
	
	/* counter for the symbols window: each 4 sample for a symbol */ 
	always @(posedge clk_sample, negedge rst)
	begin 
	 if(!rst)
		Counter_SymbolWindow <='d0; 
	 else if(offset3)
		Counter_SymbolWindow <= 'd0; 
	 else
		Counter_SymbolWindow = Counter_SymbolWindow + 'd1; 
	end 
	
	assign offset0 = (Counter_SymbolWindow == 'd0);
	assign offset1 = (Counter_SymbolWindow == 'd1);
	assign offset2 = (Counter_SymbolWindow == 'd2);
	assign offset3 = (Counter_SymbolWindow == 'd3);
	/* ----------------------------------------------------------------------------*/ 
	


endmodule