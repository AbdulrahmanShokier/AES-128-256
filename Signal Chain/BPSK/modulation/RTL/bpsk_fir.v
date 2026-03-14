module bpsk_fir_filter #(
    parameter DATA_WIDTH  = 16,   // input/output width
    parameter COEFF_WIDTH = 16,   // coefficient width
    parameter NUM_TAPS    = 33,   // number of taps
    parameter ACC_WIDTH   = 40    // accumulator width (safe margin)
)
(
    input  wire                          clk_sample,
    input  wire                          rst,
    input  wire                          valid_in,
    input  wire signed [DATA_WIDTH-1:0]  data_in,
    output reg  signed [DATA_WIDTH-1:0]  data_out,
    output                               valid_out
);

////////////////////////coeffients///////////////////////////


localparam signed [DATA_WIDTH-1:0] coeff_0_32  =  16'sd306  ;
localparam signed [DATA_WIDTH-1:0] coeff_1_31  =  16'sd144  ;
localparam signed [DATA_WIDTH-1:0] coeff_2_30  = -16'sd268  ;
localparam signed [DATA_WIDTH-1:0] coeff_3_29  = -16'sd629  ;
localparam signed [DATA_WIDTH-1:0] coeff_4_28  = -16'sd556  ;
localparam signed [DATA_WIDTH-1:0] coeff_5_27  =  16'sd90   ;
localparam signed [DATA_WIDTH-1:0] coeff_6_26  =  16'sd978  ;
localparam signed [DATA_WIDTH-1:0] coeff_7_25  =  16'sd1416 ;
localparam signed [DATA_WIDTH-1:0] coeff_8_24  =  16'sd801  ;  
localparam signed [DATA_WIDTH-1:0] coeff_9_23  = -16'sd834  ;
localparam signed [DATA_WIDTH-1:0] coeff_10_22 = -16'sd2590 ;
localparam signed [DATA_WIDTH-1:0] coeff_11_21 = -16'sd3030 ;
localparam signed [DATA_WIDTH-1:0] coeff_12_20 = -16'sd981  ;
localparam signed [DATA_WIDTH-1:0] coeff_13_19 =  16'sd3640 ;
localparam signed [DATA_WIDTH-1:0] coeff_14_18 =  16'sd9527 ;
localparam signed [DATA_WIDTH-1:0] coeff_15_17 =  16'sd14461;
localparam signed [DATA_WIDTH-1:0] coeff_16    =  16'sd16384;


/////////////////////////////////////////////////////////////
reg [3:0] valid_pipe;                                     // Pipeline to track data valid through rounds


reg signed  [DATA_WIDTH-1 : 0] data_reg [NUM_TAPS-1 : 0];        // delay line

reg signed  [DATA_WIDTH : 0] pre_add [0 : 16];

reg signed  [DATA_WIDTH + DATA_WIDTH : 0] product [0 : 16];      // 33 bits -> 16 for coff. and 17 for pre_add. 

reg signed  [DATA_WIDTH + DATA_WIDTH +1 : 0] level1_add [0 : 8]; // 34 bits -> addition of the multiplication output

reg signed  [DATA_WIDTH + DATA_WIDTH +2 : 0] level2_add [0 : 4]; // 35 bits -> addition of the level 1 addition

reg signed  [DATA_WIDTH + DATA_WIDTH +3 : 0] level3_add [0 : 2]; // 36 bits -> addition of the level 2 addition

reg signed  [DATA_WIDTH + DATA_WIDTH +4 : 0] level4_add [0 : 1]; // 37 bits -> addition of the level 3 addition

reg signed  [DATA_WIDTH + DATA_WIDTH +5 : 0] level5_add        ; // 38 bits -> addition of the level 4 addition




//////////// valid shift register ///////////

    // Pipeline Valid Logic

    always @(posedge clk_sample) 
    begin
        if (!rst) 
        begin
            valid_pipe <= 4'b0;
        end 
        else 
        begin
            valid_pipe <= {valid_pipe[2:0], valid_in};
        end
    end


    assign valid_out = valid_pipe[3];   




///////////////////// data sampled in shift register///////////////    

    integer i;
    always @(posedge clk_sample) 
    begin
        if (!rst) 
        begin
            for (i = 0; i < NUM_TAPS; i = i + 1)
                data_reg[i] <= {DATA_WIDTH{1'b0}};
        end
        else 
        begin
            data_reg[0] <= data_in;              // new sample enters
            for (i = 1; i < NUM_TAPS; i = i + 1)
                data_reg[i] <= data_reg[i-1];    // shift right
        end
    end



//////////////////// pre addition ///////////////////
    //integer k;

    always@(*)
    begin
    //     if (!rst) 
    //     begin
    //     for (k = 0; k <= 16; k = k + 1)
    //         pre_add[k] <= 0;
    //     end
    // else
        //begin
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
        pre_add[16] = {{1{data_reg[16][DATA_WIDTH-1]}}, data_reg[16]};       
        //end
    end


///////////// coefficient multiplication //////////// 

    integer l;
    always@(posedge clk_sample)
    begin
    if (!rst) 
        begin
        for (l = 0; l <= 16; l = l + 1)
            product[l] <= 0;
        end
    else
        begin
        product[0]  <= pre_add[0]   * coeff_0_32 ;
        product[1]  <= pre_add[1]   * coeff_1_31 ;
        product[2]  <= pre_add[2]   * coeff_2_30 ;
        product[3]  <= pre_add[3]   * coeff_3_29 ;
        product[4]  <= pre_add[4]   * coeff_4_28 ;
        product[5]  <= pre_add[5]   * coeff_5_27 ;
        product[6]  <= pre_add[6]   * coeff_6_26 ;
        product[7]  <= pre_add[7]   * coeff_7_25 ;
        product[8]  <= pre_add[8]   * coeff_8_24 ;
        product[9]  <= pre_add[9]   * coeff_9_23 ;
        product[10] <= pre_add[10]  * coeff_10_22;
        product[11] <= pre_add[11]  * coeff_11_21;
        product[12] <= pre_add[12]  * coeff_12_20;
        product[13] <= pre_add[13]  * coeff_13_19;
        product[14] <= pre_add[14]  * coeff_14_18;
        product[15] <= pre_add[15]  * coeff_15_17;
        product[16] <= pre_add[16]  * coeff_16   ; // center tap
        end
    end

//////////////////// level 1 addition /////////////////

    always @(*) 
    begin
        level1_add[0] = product[0]  + product[1]  ;
        level1_add[1] = product[2]  + product[3]  ;
        level1_add[2] = product[4]  + product[5]  ;
        level1_add[3] = product[6]  + product[7]  ;
        level1_add[4] = product[8]  + product[9]  ;
        level1_add[5] = product[10] + product[11] ;
        level1_add[6] = product[12] + product[13] ;
        level1_add[7] = product[14] + product[15] ;
        level1_add[8] = product[16]               ;
    end


//////////////////// level 2 addition /////////////////

    always @(*) 
    begin
        level2_add[0] = level1_add[0]  + level1_add[1]  ;
        level2_add[1] = level1_add[2]  + level1_add[3]  ;
        level2_add[2] = level1_add[4]  + level1_add[5]  ;
        level2_add[3] = level1_add[6]  + level1_add[7]  ;
        level2_add[4] = level1_add[8]                   ;
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
        level3_add[0] <= level2_add[0]  + level2_add[1]  ;
        level3_add[1] <= level2_add[2]  + level2_add[3]  ;
        level3_add[2] <= level2_add[4]                   ;
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
        // if (!rst)
        // level5_add   <= 0;
        // else
        level5_add   = level4_add[0]  + level4_add[1] ;
    end

///////////////////// truncate /////////////////////

    always @(posedge clk_sample) 
    begin
    if (!rst)
        data_out <= {DATA_WIDTH{1'b0}};
    else
        data_out <= level5_add[29:14];
end




endmodule