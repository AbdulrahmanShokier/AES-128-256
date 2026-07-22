
module Correlation_calc
#(
    parameter DATA_WIDTH  = 16,   // input/output width
	parameter PREAMBLE_LENGTH = 255 


)
(
	input wire 									clk_sample,
	input wire 									rst, 
	//input wire 									preamble_valid, 
	//input wire 				[DATA_WIDTH-1:0]	preamble_input,		// shifted at the start of process from a ROM
	input wire signed		[DATA_WIDTH-1:0] 	input_sample,		// from matched filter in Q4.12
	input wire 									valid_sample, 
	output wire signed		[DATA_WIDTH-1:0] 	corr_output			
); 


/* Internal signals */
	
	wire 	   [DATA_WIDTH-1:0] preamble_mem [PREAMBLE_LENGTH-1:0]; 	// fixed LUT below 
	
	reg signed [DATA_WIDTH-1:0] data_reg 	 [PREAMBLE_LENGTH-1:0]; 
	reg signed [DATA_WIDTH-1:0] prod 		 [PREAMBLE_LENGTH-1:0];		// 255 products with 32-bit length (doubled) Q4.12
	reg signed [DATA_WIDTH:0]   level1_add [127:0]; 	// Q5.12
	reg signed [DATA_WIDTH+1:0] level2_add [63:0];		// Q6.12 
	reg signed [DATA_WIDTH+2:0] level3_add [31:0];		// Q7.12
	reg signed [DATA_WIDTH+3:0] level4_add [15:0];		// Q8.12
	reg signed [DATA_WIDTH+4:0] level5_add [7:0];	    // Q9.12
	reg signed [DATA_WIDTH+5:0] level6_add [3:0];	    // Q10.12
	reg signed [DATA_WIDTH+6:0] level7_add [1:0];	    // Q11.12
	reg signed [DATA_WIDTH+7:0] corr_sum;				// Q12.12
	
	integer i; 

		
	
	///////////////////// shift samples in data register /////////////// 
	always@(posedge clk_sample)
	begin 
	 if(!rst)
	  begin 
		for (i=0; i<PREAMBLE_LENGTH; i=i+1)
			data_reg[i] <=  'd0; 
	  end 
	 else if(valid_sample)
	  begin 
		data_reg[PREAMBLE_LENGTH-1]<= input_sample; // to 254 
		for (i=0; i<PREAMBLE_LENGTH-1; i=i+1)
			data_reg[i] <= data_reg[i+1];			// 0 <- 1 .... 253 <- 254 
	  end 
	end 
	
	///////////// multiplication //////////// 

	always @(posedge clk_sample)
	begin
	 if (!rst)
 	  begin
	  for (i=0; i<PREAMBLE_LENGTH; i=i+1)
	 		prod[i] <= 'd0;
	  end
	 else
	  begin
	   for (i=0; i<PREAMBLE_LENGTH; i=i+1)
	 		//prod[i] <= data_reg[i] * preamble_mem[i];	// Optimize ___ ..
			prod[i] <= preamble_mem[i] ? -data_reg[i] : data_reg[i];
	  end
	end
	
	
	/* Optimize collecting up all products through levels of addition */ 
	
	//////////////////// level 1 addition /////////////////	
	always @(posedge clk_sample) begin
	 if (!rst) begin
	 	for (i=0; i<128; i=i+1)
	 		level1_add[i] <= 'd0;
	 end 
	 else begin
	 	for (i=0; i<127; i=i+1)
	 		level1_add[i] <= prod[i] + prod[254-i];
	 	level1_add[127] <= prod[127];
	 end
	end
	
	//////////////////// level 2 addition /////////////////	
	always @(posedge clk_sample) begin
	 if (!rst) begin
	 	for (i=0; i<64; i=i+1)
	 		level2_add[i] <= 'd0;
	 end
	 else begin
	 	for (i=0; i<64; i=i+1)
	 		level2_add[i] <= level1_add[i] + level1_add[127-i];
	 end
	end
	
	//////////////////// level 3 addition /////////////////	
	always @(posedge clk_sample) begin
	 if (!rst) begin
	 	for (i=0; i<32; i=i+1)
	 		level3_add[i] <= 'd0;
	 end
	 else begin
	 	for (i=0; i<32; i=i+1)
	 		level3_add[i] <= level2_add[i] + level2_add[63-i];
	 end
	end
	
	//////////////////// level 4 addition /////////////////	
	always @(posedge clk_sample) begin
	 if (!rst) begin
	 	for (i=0; i<16; i=i+1)
	 		level4_add[i] <= 'd0;
	 end
	 else begin
	 	for (i=0; i<16; i=i+1)
	 		level4_add[i] <= level3_add[i] + level3_add[31-i];
	 end
	end
	
	//////////////////// level 5 addition /////////////////	
	always @(posedge clk_sample) begin
	 if (!rst) begin
	 	for (i=0; i<8; i=i+1)
	 		level5_add[i] <= 'd0;
	 end
	 else begin
	 	for (i=0; i<8; i=i+1)
	 		level5_add[i] <= level4_add[i] + level4_add[15-i];
	 end
	end
	
	//////////////////// level 6 addition /////////////////	
	always @(posedge clk_sample) begin
     if (!rst) begin
         for (i=0; i<4; i=i+1)
             level6_add[i] <= 'd0;
     end
	 else begin
         for (i=0; i<4; i=i+1)
             level6_add[i] <= level5_add[i] + level5_add[7-i];
     end
	end

	//////////////////// level 7 addition /////////////////	
	always @(posedge clk_sample) begin
     if (!rst) begin
		for(i=0; i<2; i=i+1)
             level7_add[i] <= 'd0;
     end
	 else begin
		for(i=0; i<2; i=i+1)
			level7_add[i] <= level6_add[i] + level6_add[3-i];
     end
	end
	
	//////////////////// Correlation sum (level 8) /////////////////	
	
	always@(posedge clk_sample)
	begin 
	 if(!rst)
		corr_sum <= 'd0; 
	 else 
		corr_sum <= level7_add[0] + level7_add[1]; 
	end 

	//////////////////// Truncate the output /////////////////	
	
	assign corr_output = corr_sum[23:8]; 		// Q12.12 > Q12.4 --truncated-into--> Q12.4 (throw out most right 8 bits) 

	
	/******************************** preamble saved coefficients ********************************************/ 
	assign preamble_mem[0]=16'h0001;   assign preamble_mem[1]=16'h0000;   assign preamble_mem[2]=16'h0000;   assign preamble_mem[3]=16'h0000;   assign preamble_mem[4]=16'h0000;   assign preamble_mem[5]=16'h0001;   assign preamble_mem[6]=16'h0000;   assign preamble_mem[7]=16'h0000;   assign preamble_mem[8]=16'h0000;   assign preamble_mem[9]=16'h0001;   assign preamble_mem[10]=16'h0000;  assign preamble_mem[11]=16'h0001;  assign preamble_mem[12]=16'h0001;  assign preamble_mem[13]=16'h0001;  assign preamble_mem[14]=16'h0000;  assign preamble_mem[15]=16'h0001;
    assign preamble_mem[16]=16'h0000;  assign preamble_mem[17]=16'h0001;  assign preamble_mem[18]=16'h0001;  assign preamble_mem[19]=16'h0001;  assign preamble_mem[20]=16'h0001;  assign preamble_mem[21]=16'h0000;  assign preamble_mem[22]=16'h0001;  assign preamble_mem[23]=16'h0001;  assign preamble_mem[24]=16'h0000;  assign preamble_mem[25]=16'h0001;  assign preamble_mem[26]=16'h0001;  assign preamble_mem[27]=16'h0001;  assign preamble_mem[28]=16'h0001;  assign preamble_mem[29]=16'h0001;  assign preamble_mem[30]=16'h0000;  assign preamble_mem[31]=16'h0000;
    assign preamble_mem[32]=16'h0000;  assign preamble_mem[33]=16'h0000;  assign preamble_mem[34]=16'h0001;  assign preamble_mem[35]=16'h0001;  assign preamble_mem[36]=16'h0000;  assign preamble_mem[37]=16'h0001;  assign preamble_mem[38]=16'h0000;  assign preamble_mem[39]=16'h0000;  assign preamble_mem[40]=16'h0001;  assign preamble_mem[41]=16'h0001;  assign preamble_mem[42]=16'h0000;  assign preamble_mem[43]=16'h0001;  assign preamble_mem[44]=16'h0000;  assign preamble_mem[45]=16'h0001;  assign preamble_mem[46]=16'h0001;  assign preamble_mem[47]=16'h0000;
    assign preamble_mem[48]=16'h0001;  assign preamble_mem[49]=16'h0001;  assign preamble_mem[50]=16'h0000;  assign preamble_mem[51]=16'h0001;  assign preamble_mem[52]=16'h0000;  assign preamble_mem[53]=16'h0001;  assign preamble_mem[54]=16'h0000;  assign preamble_mem[55]=16'h0000;  assign preamble_mem[56]=16'h0000;  assign preamble_mem[57]=16'h0000;  assign preamble_mem[58]=16'h0000;  assign preamble_mem[59]=16'h0001;  assign preamble_mem[60]=16'h0000;  assign preamble_mem[61]=16'h0000;  assign preamble_mem[62]=16'h0001;  assign preamble_mem[63]=16'h0001;
    assign preamble_mem[64]=16'h0001;  assign preamble_mem[65]=16'h0000;  assign preamble_mem[66]=16'h0001;  assign preamble_mem[67]=16'h0001;  assign preamble_mem[68]=16'h0000;  assign preamble_mem[69]=16'h0000;  assign preamble_mem[70]=16'h0001;  assign preamble_mem[71]=16'h0000;  assign preamble_mem[72]=16'h0000;  assign preamble_mem[73]=16'h0001;  assign preamble_mem[74]=16'h0000;  assign preamble_mem[75]=16'h0000;  assign preamble_mem[76]=16'h0001;  assign preamble_mem[77]=16'h0001;  assign preamble_mem[78]=16'h0000;  assign preamble_mem[79]=16'h0000;
    assign preamble_mem[80]=16'h0000;  assign preamble_mem[81]=16'h0000;  assign preamble_mem[82]=16'h0000;  assign preamble_mem[83]=16'h0000;  assign preamble_mem[84]=16'h0001;  assign preamble_mem[85]=16'h0001;  assign preamble_mem[86]=16'h0001;  assign preamble_mem[87]=16'h0000;  assign preamble_mem[88]=16'h0001;  assign preamble_mem[89]=16'h0000;  assign preamble_mem[90]=16'h0000;  assign preamble_mem[91]=16'h0001;  assign preamble_mem[92]=16'h0000;  assign preamble_mem[93]=16'h0000;  assign preamble_mem[94]=16'h0000;  assign preamble_mem[95]=16'h0001;
    assign preamble_mem[96]=16'h0001;  assign preamble_mem[97]=16'h0001;  assign preamble_mem[98]=16'h0000;  assign preamble_mem[99]=16'h0000;  assign preamble_mem[100]=16'h0000; assign preamble_mem[101]=16'h0001; assign preamble_mem[102]=16'h0000; assign preamble_mem[103]=16'h0000; assign preamble_mem[104]=16'h0000; assign preamble_mem[105]=16'h0000; assign preamble_mem[106]=16'h0000; assign preamble_mem[107]=16'h0000; assign preamble_mem[108]=16'h0000; assign preamble_mem[109]=16'h0001; assign preamble_mem[110]=16'h0000; assign preamble_mem[111]=16'h0001;
    assign preamble_mem[112]=16'h0001; assign preamble_mem[113]=16'h0000; assign preamble_mem[114]=16'h0000; assign preamble_mem[115]=16'h0000; assign preamble_mem[116]=16'h0001; assign preamble_mem[117]=16'h0001; assign preamble_mem[118]=16'h0001; assign preamble_mem[119]=16'h0001; assign preamble_mem[120]=16'h0000; assign preamble_mem[121]=16'h0001; assign preamble_mem[122]=16'h0000; assign preamble_mem[123]=16'h0000; assign preamble_mem[124]=16'h0000; assign preamble_mem[125]=16'h0000; assign preamble_mem[126]=16'h0001; assign preamble_mem[127]=16'h0001;
    assign preamble_mem[128]=16'h0001; assign preamble_mem[129]=16'h0001; assign preamble_mem[130]=16'h0001; assign preamble_mem[131]=16'h0001; assign preamble_mem[132]=16'h0001; assign preamble_mem[133]=16'h0001; assign preamble_mem[134]=16'h0000; assign preamble_mem[135]=16'h0000; assign preamble_mem[136]=16'h0001; assign preamble_mem[137]=16'h0000; assign preamble_mem[138]=16'h0000; assign preamble_mem[139]=16'h0000; assign preamble_mem[140]=16'h0000; assign preamble_mem[141]=16'h0001; assign preamble_mem[142]=16'h0000; assign preamble_mem[143]=16'h0001;
    assign preamble_mem[144]=16'h0000; assign preamble_mem[145]=16'h0000; assign preamble_mem[146]=16'h0001; assign preamble_mem[147]=16'h0001; assign preamble_mem[148]=16'h0001; assign preamble_mem[149]=16'h0001; assign preamble_mem[150]=16'h0001; assign preamble_mem[151]=16'h0000; assign preamble_mem[152]=16'h0001; assign preamble_mem[153]=16'h0000; assign preamble_mem[154]=16'h0001; assign preamble_mem[155]=16'h0000; assign preamble_mem[156]=16'h0001; assign preamble_mem[157]=16'h0000; assign preamble_mem[158]=16'h0001; assign preamble_mem[159]=16'h0001;
    assign preamble_mem[160]=16'h0001; assign preamble_mem[161]=16'h0000; assign preamble_mem[162]=16'h0000; assign preamble_mem[163]=16'h0000; assign preamble_mem[164]=16'h0000; assign preamble_mem[165]=16'h0000; assign preamble_mem[166]=16'h0001; assign preamble_mem[167]=16'h0001; assign preamble_mem[168]=16'h0000; assign preamble_mem[169]=16'h0000; assign preamble_mem[170]=16'h0000; assign preamble_mem[171]=16'h0001; assign preamble_mem[172]=16'h0000; assign preamble_mem[173]=16'h0001; assign preamble_mem[174]=16'h0000; assign preamble_mem[175]=16'h0001;
    assign preamble_mem[176]=16'h0001; assign preamble_mem[177]=16'h0000; assign preamble_mem[178]=16'h0000; assign preamble_mem[179]=16'h0001; assign preamble_mem[180]=16'h0001; assign preamble_mem[181]=16'h0000; assign preamble_mem[182]=16'h0000; assign preamble_mem[183]=16'h0001; assign preamble_mem[184]=16'h0000; assign preamble_mem[185]=16'h0001; assign preamble_mem[186]=16'h0001; assign preamble_mem[187]=16'h0001; assign preamble_mem[188]=16'h0001; assign preamble_mem[189]=16'h0001; assign preamble_mem[190]=16'h0001; assign preamble_mem[191]=16'h0000;
    assign preamble_mem[192]=16'h0001; assign preamble_mem[193]=16'h0001; assign preamble_mem[194]=16'h0001; assign preamble_mem[195]=16'h0001; assign preamble_mem[196]=16'h0000; assign preamble_mem[197]=16'h0000; assign preamble_mem[198]=16'h0001; assign preamble_mem[199]=16'h0001; assign preamble_mem[200]=16'h0000; assign preamble_mem[201]=16'h0001; assign preamble_mem[202]=16'h0001; assign preamble_mem[203]=16'h0001; assign preamble_mem[204]=16'h0000; assign preamble_mem[205]=16'h0001; assign preamble_mem[206]=16'h0001; assign preamble_mem[207]=16'h0001;
    assign preamble_mem[208]=16'h0000; assign preamble_mem[209]=16'h0000; assign preamble_mem[210]=16'h0001; assign preamble_mem[211]=16'h0000; assign preamble_mem[212]=16'h0001; assign preamble_mem[213]=16'h0000; assign preamble_mem[214]=16'h0001; assign preamble_mem[215]=16'h0000; assign preamble_mem[216]=16'h0000; assign preamble_mem[217]=16'h0001; assign preamble_mem[218]=16'h0000; assign preamble_mem[219]=16'h0001; assign preamble_mem[220]=16'h0000; assign preamble_mem[221]=16'h0000; assign preamble_mem[222]=16'h0000; assign preamble_mem[223]=16'h0001;
    assign preamble_mem[224]=16'h0000; assign preamble_mem[225]=16'h0000; assign preamble_mem[226]=16'h0001; assign preamble_mem[227]=16'h0000; assign preamble_mem[228]=16'h0001; assign preamble_mem[229]=16'h0001; assign preamble_mem[230]=16'h0000; assign preamble_mem[231]=16'h0001; assign preamble_mem[232]=16'h0000; assign preamble_mem[233]=16'h0000; assign preamble_mem[234]=16'h0000; assign preamble_mem[235]=16'h0001; assign preamble_mem[236]=16'h0001; assign preamble_mem[237]=16'h0000; assign preamble_mem[238]=16'h0000; assign preamble_mem[239]=16'h0001;
    assign preamble_mem[240]=16'h0001; assign preamble_mem[241]=16'h0001; assign preamble_mem[242]=16'h0000; assign preamble_mem[243]=16'h0000; assign preamble_mem[244]=16'h0001; assign preamble_mem[245]=16'h0001; assign preamble_mem[246]=16'h0001; assign preamble_mem[247]=16'h0001; assign preamble_mem[248]=16'h0000; assign preamble_mem[249]=16'h0000; assign preamble_mem[250]=16'h0000; assign preamble_mem[251]=16'h0001; assign preamble_mem[252]=16'h0001; assign preamble_mem[253]=16'h0000; assign preamble_mem[254]=16'h0001;



	


endmodule

