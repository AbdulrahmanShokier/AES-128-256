module psk16_fir_MF_filter #(
    parameter DATA_WIDTH  = 16,   // input/output width
    parameter FRAC_WIDTH = 14,    // Q2.14
    parameter COEFF_WIDTH = 16,   // coefficient width
    parameter NUM_TAPS    = 65   // number of taps
)
(
    input  wire                          clk_sample,
    input  wire                          rst,
    input  wire signed [DATA_WIDTH-1:0]  data_in,
    output reg  signed [DATA_WIDTH-1:0]  data_out
);

////////////////////////coeffients///////////////////////////

localparam signed [COEFF_WIDTH-1 : 0] coeff_0_64  = -16'sd18  ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_1_63  =  16'sd9   ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_2_62  =  16'sd16  ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_3_61  = -16'sd21  ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_4_60  = -16'sd2   ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_5_59  =  16'sd23  ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_6_58  = -16'sd18  ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_7_57  = -16'sd9   ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_8_56  =  16'sd33  ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_9_55  = -16'sd17  ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_10_54 = -16'sd30  ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_11_53 =  16'sd42  ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_12_52 =  16'sd5   ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_13_51 = -16'sd47  ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_14_50 =  16'sd38  ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_15_49 =  16'sd18  ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_16_48 = -16'sd76  ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_17_47 =  16'sd44  ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_18_46 =  16'sd81  ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_19_45 = -16'sd115 ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_20_44 = -16'sd23  ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_21_43 =  16'sd142 ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_22_42 = -16'sd114 ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_23_41 = -16'sd45  ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_24_40 =  16'sd324 ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_25_39 = -16'sd280 ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_26_38 = -16'sd574 ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_27_37 =  16'sd1000;
localparam signed [COEFF_WIDTH-1 : 0] coeff_28_36 =  16'sd813 ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_29_35 = -16'sd2610;
localparam signed [COEFF_WIDTH-1 : 0] coeff_30_34 = -16'sd985 ;
localparam signed [COEFF_WIDTH-1 : 0] coeff_31_33 =  16'sd9536;
localparam signed [COEFF_WIDTH-1 : 0] coeff_32    =  16'sd16384; // center tap

/////////////////////////////////////////////////////////////


reg signed  [DATA_WIDTH-1 : 0] data_reg [NUM_TAPS-1 : 0];        // delay line

reg signed  [DATA_WIDTH : 0] pre_add [0 : 32];

reg signed  [DATA_WIDTH + DATA_WIDTH : 0] product [0 : 32];      // 33 bits -> 16 for coff. and 17 for pre_add. 

reg signed  [DATA_WIDTH + DATA_WIDTH +1 : 0] level1_add [0 : 16]; // 34 bits
reg signed  [DATA_WIDTH + DATA_WIDTH +2 : 0] level2_add [0 : 8];  // 35 bits
reg signed  [DATA_WIDTH + DATA_WIDTH +3 : 0] level3_add [0 : 4];  // 36 bits
reg signed  [DATA_WIDTH + DATA_WIDTH +4 : 0] level4_add [0 : 2];  // 37 bits
reg signed  [DATA_WIDTH + DATA_WIDTH +5 : 0] level5_add [0 : 1];  // 38 bits
reg signed  [DATA_WIDTH + DATA_WIDTH +6 : 0] level6_add        ;  // 39 bits


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
            data_reg[0] <= data_in;
            for (i = 1; i < NUM_TAPS; i = i + 1)
                data_reg[i] <= data_reg[i-1];
        end
    end


//////////////////// pre addition ///////////////////

    always@(*)
    begin
        pre_add[0]  = data_reg[0]  + data_reg[64];
        pre_add[1]  = data_reg[1]  + data_reg[63];
        pre_add[2]  = data_reg[2]  + data_reg[62];
        pre_add[3]  = data_reg[3]  + data_reg[61];
        pre_add[4]  = data_reg[4]  + data_reg[60];
        pre_add[5]  = data_reg[5]  + data_reg[59];
        pre_add[6]  = data_reg[6]  + data_reg[58];
        pre_add[7]  = data_reg[7]  + data_reg[57];
        pre_add[8]  = data_reg[8]  + data_reg[56];
        pre_add[9]  = data_reg[9]  + data_reg[55];
        pre_add[10] = data_reg[10] + data_reg[54];
        pre_add[11] = data_reg[11] + data_reg[53];
        pre_add[12] = data_reg[12] + data_reg[52];
        pre_add[13] = data_reg[13] + data_reg[51];
        pre_add[14] = data_reg[14] + data_reg[50];
        pre_add[15] = data_reg[15] + data_reg[49];
        pre_add[16] = data_reg[16] + data_reg[48];
        pre_add[17] = data_reg[17] + data_reg[47];
        pre_add[18] = data_reg[18] + data_reg[46];
        pre_add[19] = data_reg[19] + data_reg[45];
        pre_add[20] = data_reg[20] + data_reg[44];
        pre_add[21] = data_reg[21] + data_reg[43];
        pre_add[22] = data_reg[22] + data_reg[42];
        pre_add[23] = data_reg[23] + data_reg[41];
        pre_add[24] = data_reg[24] + data_reg[40];
        pre_add[25] = data_reg[25] + data_reg[39];
        pre_add[26] = data_reg[26] + data_reg[38];
        pre_add[27] = data_reg[27] + data_reg[37];
        pre_add[28] = data_reg[28] + data_reg[36];
        pre_add[29] = data_reg[29] + data_reg[35];
        pre_add[30] = data_reg[30] + data_reg[34];
        pre_add[31] = data_reg[31] + data_reg[33];
        pre_add[32] = {{1{data_reg[32][DATA_WIDTH-1]}}, data_reg[32]}; // center tap sign-extended
    end


///////////// coefficient multiplication //////////// 

    integer l;
    always@(posedge clk_sample)
    begin
        if (!rst) 
        begin
            for (l = 0; l <= 32; l = l + 1)
                product[l] <= 0;
        end
        else
        begin
            product[0]  <= pre_add[0]  * coeff_0_64 ;
            product[1]  <= pre_add[1]  * coeff_1_63 ;
            product[2]  <= pre_add[2]  * coeff_2_62 ;
            product[3]  <= pre_add[3]  * coeff_3_61 ;
            product[4]  <= pre_add[4]  * coeff_4_60 ;
            product[5]  <= pre_add[5]  * coeff_5_59 ;
            product[6]  <= pre_add[6]  * coeff_6_58 ;
            product[7]  <= pre_add[7]  * coeff_7_57 ;
            product[8]  <= pre_add[8]  * coeff_8_56 ;
            product[9]  <= pre_add[9]  * coeff_9_55 ;
            product[10] <= pre_add[10] * coeff_10_54;
            product[11] <= pre_add[11] * coeff_11_53;
            product[12] <= pre_add[12] * coeff_12_52;
            product[13] <= pre_add[13] * coeff_13_51;
            product[14] <= pre_add[14] * coeff_14_50;
            product[15] <= pre_add[15] * coeff_15_49;
            product[16] <= pre_add[16] * coeff_16_48;
            product[17] <= pre_add[17] * coeff_17_47;
            product[18] <= pre_add[18] * coeff_18_46;
            product[19] <= pre_add[19] * coeff_19_45;
            product[20] <= pre_add[20] * coeff_20_44;
            product[21] <= pre_add[21] * coeff_21_43;
            product[22] <= pre_add[22] * coeff_22_42;
            product[23] <= pre_add[23] * coeff_23_41;
            product[24] <= pre_add[24] * coeff_24_40;
            product[25] <= pre_add[25] * coeff_25_39;
            product[26] <= pre_add[26] * coeff_26_38;
            product[27] <= pre_add[27] * coeff_27_37;
            product[28] <= pre_add[28] * coeff_28_36;
            product[29] <= pre_add[29] * coeff_29_35;
            product[30] <= pre_add[30] * coeff_30_34;
            product[31] <= pre_add[31] * coeff_31_33;
            product[32] <= pre_add[32] * coeff_32   ;
        end
    end

//////////////////// level 1 addition /////////////////
// 33 products -> 17 pairs (16 pairs + 1 leftover)
    always @(*) 
    begin
        level1_add[0]  = product[0]  + product[1] ;
        level1_add[1]  = product[2]  + product[3] ;
        level1_add[2]  = product[4]  + product[5] ;
        level1_add[3]  = product[6]  + product[7] ;
        level1_add[4]  = product[8]  + product[9] ;
        level1_add[5]  = product[10] + product[11];
        level1_add[6]  = product[12] + product[13];
        level1_add[7]  = product[14] + product[15];
        level1_add[8]  = product[16] + product[17];
        level1_add[9]  = product[18] + product[19];
        level1_add[10] = product[20] + product[21];
        level1_add[11] = product[22] + product[23];
        level1_add[12] = product[24] + product[25];
        level1_add[13] = product[26] + product[27];
        level1_add[14] = product[28] + product[29];
        level1_add[15] = product[30] + product[31];
        level1_add[16] = product[32]              ;
    end

//////////////////// level 2 addition /////////////////
// 17 -> 9 (8 pairs + 1 leftover)
    always @(*) 
    begin
        level2_add[0] = level1_add[0]  + level1_add[1] ;
        level2_add[1] = level1_add[2]  + level1_add[3] ;
        level2_add[2] = level1_add[4]  + level1_add[5] ;
        level2_add[3] = level1_add[6]  + level1_add[7] ;
        level2_add[4] = level1_add[8]  + level1_add[9] ;
        level2_add[5] = level1_add[10] + level1_add[11];
        level2_add[6] = level1_add[12] + level1_add[13];
        level2_add[7] = level1_add[14] + level1_add[15];
        level2_add[8] = level1_add[16]                 ;
    end

//////////////////// level 3 addition /////////////////
// 9 -> 5 (4 pairs + 1 leftover) -- registered
    always@(posedge clk_sample)
    begin
        if (!rst) 
        begin
            level3_add[0] <= 0;
            level3_add[1] <= 0;
            level3_add[2] <= 0;
            level3_add[3] <= 0;
            level3_add[4] <= 0;
        end
        else
        begin
            level3_add[0] <= level2_add[0] + level2_add[1];
            level3_add[1] <= level2_add[2] + level2_add[3];
            level3_add[2] <= level2_add[4] + level2_add[5];
            level3_add[3] <= level2_add[6] + level2_add[7];
            level3_add[4] <= level2_add[8]                ;
        end
    end

//////////////////// level 4 addition /////////////////
// 5 -> 3 (2 pairs + 1 leftover)
    always @(*) 
    begin
        level4_add[0] = level3_add[0] + level3_add[1];
        level4_add[1] = level3_add[2] + level3_add[3];
        level4_add[2] = level3_add[4]                ;
    end

//////////////////// level 5 addition /////////////////
// 3 -> 2
    always @(*) 
    begin
        level5_add[0] = level4_add[0] + level4_add[1];
        level5_add[1] = level4_add[2]                ;
    end

//////////////////// level 6 addition /////////////////
// 2 -> 1 (final sum)
    always @(*) 
    begin
        level6_add = level5_add[0] + level5_add[1];
    end

///////////////////// truncate /////////////////////

    always @(posedge clk_sample) 
    begin
        if (!rst)
            data_out <= {DATA_WIDTH{1'b0}};
        else
            data_out <= level6_add[31:16];  // remove Q2.14 scaling
    end

endmodule