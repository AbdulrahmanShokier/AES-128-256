

/* just one modifcation after 'bpsk_fir_filter': 

   I change the scaling for 'data_out' to >> 14+2 bits
   as output exeeded the value for 16-bit output, 
   so it's required more 2-bit shift to fit the 
   value in 16-bit (at the expense of decreasing the percision)
*/ 
   

module matchedFilter #(
    parameter DATA_WIDTH  = 16,   // input/output width
    parameter FRAC_WIDTH  = 14,   // Q2.14 format
    parameter COEFF_WIDTH = 16,   // coefficient width
    parameter NUM_TAPS    = 33    // number of taps for 32-order FIR 
)

(
	input wire 							clk_sample,
	input wire 							rst, 
	input wire signed  [DATA_WIDTH-1:0] data_in, 
	output reg signed  [DATA_WIDTH-1:0] data_out
);

//////////////////////// Normalized Coeffs - Q2.14 format ////////////////////////////

localparam signed [COEFF_WIDTH-1 : 0] coeff_0_32  =  16'sd306  ;   
localparam signed [COEFF_WIDTH-1 : 0] coeff_1_31  =  16'sd144  ;   
localparam signed [COEFF_WIDTH-1 : 0] coeff_2_30  = -16'sd268  ;   
localparam signed [COEFF_WIDTH-1 : 0] coeff_3_29  = -16'sd629  ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_4_28  = -16'sd556  ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_5_27  =  16'sd90   ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_6_26  =  16'sd978  ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_7_25  =  16'sd1416 ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_8_24  =  16'sd801  ;  
localparam signed [COEFF_WIDTH-1 : 0] coeff_9_23  = -16'sd834  ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_10_22 = -16'sd2590 ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_11_21 = -16'sd3030 ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_12_20 = -16'sd981  ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_13_19 =  16'sd3640 ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_14_18 =  16'sd9527 ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_15_17 =  16'sd14461;
localparam signed [COEFF_WIDTH-1 : 0] coeff_16    =  16'sd16384;  

//////////////////////////////////////////////////////////////////////////////////////

/* Internal array of signals */ 

reg signed [DATA_WIDTH-1:0] data_reg [NUM_TAPS-1:0]; 	// the delay line 
reg signed [DATA_WIDTH:0]   pre_add  [16:0];			// one more bit for addition 
reg signed [DATA_WIDTH*2:0] product  [16:0];			// 33 bits: 16 for coff and 17 for pre_add

/* for addition levels */ 
reg signed [DATA_WIDTH*2+1:0] level1_add [8:0];  		// 34 bits -> addition of the multiplication output
reg signed [DATA_WIDTH*2+2:0] level2_add [4:0];			// 35 bits -> addition of the level 1 addition output
reg signed [DATA_WIDTH*2+3:0] level3_add [2:0]; 		// 36 bits -> addition of the level 2 addition output
reg signed [DATA_WIDTH*2+4:0] level4_add [1:0]; 		// 37 bits -> addition of the level 3 addition output
reg signed [DATA_WIDTH*2+5:0] level5_add;       		// 38 bits -> addition of the level 4 addition output
						 
                                                
///////////////////// Data sampled in shift register///////////////    
	integer i;                                 
	always @(posedge clk_sample)
	 begin 
		if(!rst)
		 begin 
			for(i=0; i<NUM_TAPS; i=i+1)
				data_reg[i] <= {DATA_WIDTH{1'b0}}; 
		 end
		else
		 begin 
			data_reg[0] <= data_in; 			// New sample enters 
			for(i=0; i<NUM_TAPS-1; i=i+1)
				data_reg[i+1] <= data_reg[i];	// Shift right through the delay line 
		 end 
		
	 end 
	 
	 
//////////////////// Pre-addition ///////////////////

	always@(*)
	 begin 
		pre_add[0]  = data_reg[0]  + data_reg[32]; 
		pre_add[1]  = data_reg[1]  + data_reg[31]; 
		pre_add[2]  = data_reg[2]  + data_reg[30]; 
		pre_add[3]  = data_reg[3]  + data_reg[29]; 
		pre_add[4]  = data_reg[4]  + data_reg[28]; 
		pre_add[5]  = data_reg[5]  + data_reg[27]; 
		pre_add[6]  = data_reg[6]  + data_reg[26]; 
		pre_add[7]  = data_reg[7]  + data_reg[25]; 
		pre_add[8]  = data_reg[8]  + data_reg[24]; 
		pre_add[9]  = data_reg[9]  + data_reg[23]; 
		pre_add[10] = data_reg[10] + data_reg[22]; 
		pre_add[11] = data_reg[11] + data_reg[21]; 
		pre_add[12] = data_reg[12] + data_reg[20]; 
		pre_add[13] = data_reg[13] + data_reg[19]; 
		pre_add[14] = data_reg[14] + data_reg[18]; 
		pre_add[15] = data_reg[15] + data_reg[17];
		pre_add[16] = {{data_reg[16][DATA_WIDTH-1]},data_reg[16]};
			// Sign-extended to be 17 bits as pre_add array.  
	 end 
	 
	 
///////////// Coefficient multiplication //////////// 
	
	integer l; 
	always@(posedge clk_sample)
	 begin 
		if(!rst)
		 begin 
			for(l=0; l<16; l=l+1)
				product[l] <= 'd0;
		 end 
		else
		 begin
			product[0]  <= pre_add[0]  * coeff_0_32 ;
			product[1]  <= pre_add[1]  * coeff_1_31 ;
			product[2]  <= pre_add[2]  * coeff_2_30 ;
			product[3]  <= pre_add[3]  * coeff_3_29 ;
			product[4]  <= pre_add[4]  * coeff_4_28 ;
			product[5]  <= pre_add[5]  * coeff_5_27 ;
			product[6]  <= pre_add[6]  * coeff_6_26 ;
			product[7]  <= pre_add[7]  * coeff_7_25 ;
			product[8]  <= pre_add[8]  * coeff_8_24 ;
			product[9]  <= pre_add[9]  * coeff_9_23 ;
			product[10] <= pre_add[10] * coeff_10_22;
			product[11] <= pre_add[11] * coeff_11_21;
			product[12] <= pre_add[12] * coeff_12_20;
			product[13] <= pre_add[13] * coeff_13_19;
			product[14] <= pre_add[14] * coeff_14_18;
			product[15] <= pre_add[15] * coeff_15_17;
			product[16] <= pre_add[16] * coeff_16; 		// center tap
		 end 
	 end 


/* Optimize collecting up all products through levels of addition */ 

//////////////////// level 1 addition /////////////////
 
	always@(*)
	 begin 
        level1_add[0] = product[0]  + product[1];
        level1_add[1] = product[2]  + product[3];
        level1_add[2] = product[4]  + product[5];
        level1_add[3] = product[6]  + product[7];
        level1_add[4] = product[8]  + product[9];
        level1_add[5] = product[10] + product[11];
        level1_add[6] = product[12] + product[13];
        level1_add[7] = product[14] + product[15];
        level1_add[8] = product[16];   
	 end 
	 
//////////////////// level 2 addition /////////////////
    always @(*) 
    begin
        level2_add[0] = level1_add[0] + level1_add[1];
        level2_add[1] = level1_add[2] + level1_add[3];
        level2_add[2] = level1_add[4] + level1_add[5];
        level2_add[3] = level1_add[6] + level1_add[7];
        level2_add[4] = level1_add[8];
    end

//////////////////// level 3 addition /////////////////
    always@(posedge clk_sample)
    begin
    if (!rst) 
        begin
        level3_add[0] <= 0;
        level3_add[1] <= 0;
        level3_add[2] <= 0;
        end
    else
        begin
        level3_add[0] <= level2_add[0] + level2_add[1];
        level3_add[1] <= level2_add[2] + level2_add[3];
        level3_add[2] <= level2_add[4];
        end
    end
	
//////////////////// level 4 addition /////////////////
    always @(*) 
    begin
        level4_add[0] = level3_add[0]  + level3_add[1]  ;
        level4_add[1] = level3_add[2]                   ;
    end    

//////////////////// level 5 addition /////////////////
    always@(*)
    begin
        level5_add   = level4_add[0]  + level4_add[1] ;
    end
	
	
///////////////////// truncate /////////////////////

	always@(posedge clk_sample)
	 begin 
		if(!rst)
			data_out <= {DATA_WIDTH{1'b0}};
		else 
			data_out <= level5_add[31:16];	// fit in Q4.12
	 
	 end 
	 
	
endmodule











  