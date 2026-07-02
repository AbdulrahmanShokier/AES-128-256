
module samplerPlusPreamDetector		// integration (sampler + preamb_detector)
#(
	parameter DATA_WIDTH = 16,
	parameter NO_OFFSETS = 4		// OSR = 4
)
(	
	input wire 							clk,
    input wire 							rst, 
	
	/* from sampler ports */ 
    input wire signed [DATA_WIDTH-1:0]  sampler_in,			// Matched Filter output - read from tb (for now)
	  		
	output wire 						valid_frame,		// to test 

	/* others */ 
	output wire signed [DATA_WIDTH-1:0] sample_buffered
	
);
	/* internal */ 
    wire signed [DATA_WIDTH-1:0]  sampler_out0; 
    wire signed [DATA_WIDTH-1:0]  sampler_out1;	
    wire signed [DATA_WIDTH-1:0]  sampler_out2;	
    wire signed [DATA_WIDTH-1:0]  sampler_out3;
	wire 		[NO_OFFSETS-1:0]  offset_vld;

	
	
Sampler samp0(
.clk_sample(clk),
.rst(rst), 
.data_in(sampler_in),
.data_out0(sampler_out0), 
.data_out1(sampler_out1),	
.data_out2(sampler_out2),	
.data_out3(sampler_out3),
.offset_vld(offset_vld[NO_OFFSETS-1:0])
);

/* 14-length delay line to maintain the correct sample offset 14 cycles */ 
bufferDelay14 buf0(
.clk(clk),
.rst(rst),
.in(sampler_in),
.out(sample_buffered)			/* an input to a next-stage sampler (sampler after preamble detection) */ 
);

pream_detector preamb0(
.clk(clk),
.rst(rst),
.input0(sampler_out0), 	
.input1(sampler_out1), 	
.input2(sampler_out2), 	
.input3(sampler_out3),
.offset_vld(offset_vld[NO_OFFSETS-1:0]), 
.valid_frame(valid_frame)
);


















endmodule