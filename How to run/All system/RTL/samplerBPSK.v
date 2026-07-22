
module samplerBPSK 
#(
	parameter DATA_WIDTH = 16,
	parameter FRAME_LENGTH = 256 + 20, // consider 20-bit payload ....
	parameter CONTROL_LENGTH = 256,
	parameter PAYLOAD_LENGTH = 20

)

(
	input wire 							clk,
	input wire 							rst,
	input wire 							valid_frame,
	input wire signed [DATA_WIDTH-1:0] 	samplerIn, 		// the delayed MF_Out
	
	output reg signed [DATA_WIDTH-1:0]  samplerOut,
	output reg 							sample_valid,	// vaild sample (each 4 cycles)
	
	output reg 							control_valid, payload_valid
);
	

	reg [1:0] 							counter4; 	// 0,1,2,3,0 
	reg [$clog2(FRAME_LENGTH):0]		FrameCounter; 
	reg									Frame_flag; 
	
	/* logic for downsampler */
	always@(posedge clk)
	begin 
	 if(!rst)
		samplerOut <= 'd0; 
	 else if(valid_frame || (Frame_flag && counter4 == 'd3))
		begin 
		samplerOut <= samplerIn; 
		end 
	end 
	
	always@(posedge clk)
	begin 
	 if(!rst)
		sample_valid <= 1'b0; 
	 else if((counter4 == 'd0) && Frame_flag)		// 1 or what ??..??
		sample_valid <= 1'b1; 
	 else 
		sample_valid <= 1'b0; 
	end 
	
	
	
	/* logic for counter4 */
	always@(posedge clk)
	begin 
	 if(!rst)
		counter4 <= 'd0; 
	 else if (valid_frame)
		counter4 <= 'd0; 
	 else
		counter4 <= counter4 + 'd1;	// overflow 100 = 00 (correct)
	end 

	
	/* logic to keep the effect of the one-pule valid_frame (until the frame ends) */ 
	always@(posedge clk)
	begin 
	 if(!rst)
	  Frame_flag <= 'b0; 
	 else if(valid_frame)
	  Frame_flag <= 'b1; 		// to sample the correct offset for all the frame time
	 else if (FrameCounter == FRAME_LENGTH)										// Or -1 ??????..????????
	  Frame_flag <= 'b0; 
	end 
	
	/* logic for control_valid & payload_valid */ 
	always@(posedge clk)
	begin 
	 if(!rst)
	  begin 
	  control_valid <= 'd0;
	  payload_valid <= 'd0; 
	  end 
	 else if (valid_frame)
	  control_valid <= 'd1; 
	 else if((FrameCounter == CONTROL_LENGTH) && (counter4 == 'd0))
	  begin 
		control_valid <= 'd0; 
		payload_valid <= 'd1; 
	  end
	 else if(FrameCounter == CONTROL_LENGTH)
		payload_valid <= 'd0; 
	 else if (FrameCounter == FRAME_LENGTH)
		payload_valid <= 'd0; 
	end 
	
	
	/* logic for frame counter: count for preamble + payload */
	always@(posedge clk)
	begin 
	 if(!rst)
	  FrameCounter <= 'd0; 
	 else if (valid_frame || (Frame_flag && counter4 == 'd3))	// 1 or what ??..??
	  FrameCounter <= FrameCounter + 'd1;
	 else if (FrameCounter == FRAME_LENGTH)		// or -1 ????????.....??????
	  FrameCounter <= 'd0; 
	end 
	
	

endmodule 
	
	
	
	