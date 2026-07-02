
module Rx_ControlField
#(
	parameter Control_Length = 256
)

(
	input wire 						clk, 
	input wire 						rst, 
	input wire 						control_valid,
	input wire 						valid_in, 	// for Rb rate (sample_valid)
	input wire 						In, 			// bit
	output reg [Control_Length-1:0] Control_register,
	output reg 						Control_complete		// to notify that control field is complete & to notify
																// also the payload detector to start to take from 
																	// sampler.		
); 

	reg [3:0] controlValid_pipe; 						// need to maintain it for 4 more cycles (either logic will not work well)
	integer i; 
	reg [$clog2(Control_Length):0]	counter_control;	// 0->255 

	
	/* maintain control_valid for more 4 cycles */ 
	always@(posedge clk or negedge rst)
	begin 
	 if(!rst)
		controlValid_pipe <= 'd0; 
	 else 
	    controlValid_pipe[3] <= control_valid; 
	    controlValid_pipe[2] <= controlValid_pipe[3];  
	    controlValid_pipe[1] <= controlValid_pipe[2];  
	    controlValid_pipe[0] <= controlValid_pipe[1];  
	end 
	
	
	always@(posedge clk, negedge rst)
	begin 
	 if(!rst)
		Control_register <= 'd0; 
	 else if(valid_in)
	  begin
		Control_register[255] <= In;
		for(i=0; i<Control_Length-1; i=i+1) 
			Control_register[i] <= Control_register[i+1];		// 255 -> 254 .. 1 -> 0
	 end 
	end 
	
	/* count for control */ 
	always@(posedge clk, negedge rst)
	begin
	 if(!rst)
	  counter_control <= 'd0; 
	 else if((control_valid||controlValid_pipe[0]) && valid_in)
	  counter_control <= counter_control + 'd1;
	 else if(counter_control == 'd256)
	  counter_control <= 'd0; 
	end 
	
	always@(posedge clk or negedge rst) 
	begin
	 if(!rst)
	  Control_complete <= 'd0; 
	 else if (counter_control == 'd256)
	  Control_complete <= 'd1; 
	 else 
	  Control_complete = 'b0; 

	 end 


endmodule