
module pream_detector 
#( 
	parameter DATA_WIDTH = 16, 
	parameter PREAMBLE_WIDTH = 255,
	parameter NO_OFFSETS = 4 		// OSR = 4
)

(
	input wire 								clk,
	input wire 								rst,
	input wire signed [DATA_WIDTH-1:0] 		input0, 	// offset 0 from sampler 
	input wire signed [DATA_WIDTH-1:0] 		input1, 	// offset 1 from sampler 
	input wire signed [DATA_WIDTH-1:0] 		input2, 	// offset 2 from sampler 
	input wire signed [DATA_WIDTH-1:0] 		input3, 	// offset 3 from sampler 
	input wire 		  [NO_OFFSETS-1:0] 		offset_vld,
	output wire 							valid_frame

); 

	/* Signals */
	wire [DATA_WIDTH-1:0] CorrOut0; 
	wire [DATA_WIDTH-1:0] CorrOut1; 
	wire [DATA_WIDTH-1:0] CorrOut2; 
	wire [DATA_WIDTH-1:0] CorrOut3;
	
	wire [DATA_WIDTH-1:0] 			OutOfComp01;
	wire [$clog2(NO_OFFSETS)-1:0]	OutOfComp01_no; 
	
	wire [DATA_WIDTH-1:0] 			OutOfComp23;
	wire [$clog2(NO_OFFSETS)-1:0]	OutOfComp23_no; 
	
	wire [DATA_WIDTH-1:0] 			OutOfComp0123; 		// the biggest out of 4 samples (local peak)
	wire [$clog2(NO_OFFSETS)-1:0]	OutOfComp0123_no;	// which offset 

	wire [DATA_WIDTH-1:0] 			CorrExceedThr; 		// the one who exceedes the threshold (candidate global peak)
	wire [$clog2(NO_OFFSETS)-1:0]	CorrExceedThr_no;	// its offset  
	wire 							ExceedTh_top; 		// Exceed flag, Exceeded or not? 


	

	
	/* The four correlators */ 
Correlation_calc corr0(
.clk_sample(clk),
.rst(rst),
.input_sample(input0),
.valid_sample(offset_vld[0]),	
.corr_output(CorrOut0)
);

Correlation_calc corr1(
.clk_sample(clk),
.rst(rst), 
.input_sample(input1),	
.valid_sample(offset_vld[1]),	
.corr_output(CorrOut1)
);

Correlation_calc corr2(
.clk_sample(clk),
.rst(rst), 
.input_sample(input2),
.valid_sample(offset_vld[2]),		
.corr_output(CorrOut2)	
);

Correlation_calc corr3(
.clk_sample(clk),
.rst(rst), 
.input_sample(input3),
.valid_sample(offset_vld[3]),		
.corr_output(CorrOut3)
);
	/* The comparators */ 
comparator_2in comp01(
.clk_sample(clk),
.rst(rst),
.in1(CorrOut0),
.in2(CorrOut1),
.out(OutOfComp01)
);

comparator_2in comp23(
.clk_sample(clk),
.rst(rst),
.in1(CorrOut2),
.in2(CorrOut3),
.out(OutOfComp23)
);

	/* the best local peak (out of 4) */
comparator_2in comp0123(
.clk_sample(clk),
.rst(rst),
.in1(OutOfComp01),
.in2(OutOfComp23),
.out(OutOfComp0123)
);

	/* Threshold comparator to find global maximum peak */ 
comparator_threshld comp_last(
.clk_sample(clk),
.rst(rst),
.in(OutOfComp0123),
.ValidFrame(valid_frame)
);















endmodule