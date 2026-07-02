
module Rx_chainTop		// integration (sampler + preamb_detector)
#(
	parameter DATA_WIDTH = 16,
	parameter Control_Length = 256

)

(
	input wire 								clk,
	input wire 								rst, 
	
	input wire signed [DATA_WIDTH-1:0] 		RxInBpsk, 				// which include the transmitted Shaping filter output (preamble + control)
	input wire signed [DATA_WIDTH-1:0] 		RxIn16pskI, 			// inphase of payload 	
	input wire signed [DATA_WIDTH-1:0] 		RxIn16pskQ, 			// quadrature of payload 
	
	output wire 	  [Control_Length-1:0] 	Control_register,
	output wire 							Control_complete
	
	
	
			
);

	/* internal */ 
	wire signed [DATA_WIDTH-1:0]	MF_Out_bpsk;
	wire signed [DATA_WIDTH-1:0]	MF_Out_16pskI;
	wire signed [DATA_WIDTH-1:0]	MF_Out_16pskQ;
	
	wire signed [DATA_WIDTH-1:0] 	sampleBPSK_buffered;
	wire signed [DATA_WIDTH-1:0] 	sample16pskI_buffered;
	wire signed [DATA_WIDTH-1:0] 	sample16pskQ_buffered;
	
	/* samplerBPSK output */
	wire signed [DATA_WIDTH-1:0] 	bpsk_sample_valid; 	// beginning from first bit of "Control field" until end of "payload"
	wire 							bpsk_valid;
	wire 							control_valid;
	wire							payload_valid;		// synchronous with both sample16pskI_buffered & sample16pskQ_buffered
		
	/* bpskDecision sginals */
	wire bitDecided; 
	wire bitValid; 
	
	/* Payload detection signals */ 
	
	
	/*... your payload signals ... */ 
	
	


	
/* MF for bpsk */ 
matchedFilter MF0(
.clk_sample(clk),
.rst(rst), 
.data_in(RxInBpsk), 
.data_out(MF_Out_bpsk)
);
/* MF for I of 16psk */ 
matchedFilter MF1(
.clk_sample(clk),
.rst(rst), 
.data_in(RxIn16pskI), 
.data_out(MF_Out_16pskI)
);
/* MF for Q of 16psk */ 
matchedFilter MF2(
.clk_sample(clk),
.rst(rst), 
.data_in(RxIn16pskQ), 
.data_out(MF_Out_16pskQ)
);

/* bpsk chain: preamble detection -> sampler for preamble -> decision -> control field detection */ 

samplerPlusPreamDetector SamplerPlusPream0(
.clk(clk),
.rst(rst),
.sampler_in(MF_Out_bpsk),
/* test */ 
//.preamb_validCoeff(preamb_validCoeff),
//.preamb_coeff(preamb_coeff),		
.valid_frame(valid_frame),		
.sample_buffered(sampleBPSK_buffered)		/* It's output of a bufferDelay: open the module to see */ 
);

/* one-offset sampler for bpsk after preamble detection */ 
samplerBPSK samplerBpsk0(
.clk(clk),
.rst(rst),
.valid_frame(valid_frame),
.samplerIn(sampleBPSK_buffered), 	
.samplerOut(bpsk_sample_valid),
.sample_valid(bpsk_valid),
.control_valid(control_valid),
.payload_valid(payload_valid)
);

bpskDecision dec0(
.clk(clk),
.rst(rst),
.In(bpsk_sample_valid),		
.valid_in(bpsk_valid),
.Out(bitDecided),
.Out_vld(bitValid)
);

Rx_ControlField ContField0(
.clk(clk), 
.rst(rst), 
.control_valid(control_valid),
.valid_in(bitValid), 
.In(bitDecided), 			
.Control_register(Control_register),
.Control_complete(Control_complete)
);

/***************************************************************************************************/ 

/* Pay-load detection now: MF1, MF2 -> bufferDelay -> detection */

/* inphase buffering */
/* 11-length delay line to maintain the correct sample offset 11 cycles */   
bufferDelay12 buf1(
.clk(clk),
.rst(rst),
.in(MF_Out_16pskI),
.out(sample16pskI_buffered)			/* an input to a next-stage one-offset sampler (sampler for Inphase of payload) */ 
);

/* quadrature buffering */ 
/* 11-length delay line to maintain the correct sample offset 11 cycles */ 
bufferDelay12 buf2(
.clk(clk),
.rst(rst),
.in(MF_Out_16pskQ),
.out(sample16pskQ_buffered)			/* an input to a next-stage one-offset sampler (sampler for Quadrature of payload) */ 
);









endmodule





