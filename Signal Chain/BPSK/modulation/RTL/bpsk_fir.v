module bpsk_fir_filter #(
    parameter DATA_WIDTH  = 16,   // input/output width
    parameter COEFF_WIDTH = 16,   // coefficient width
    parameter NUM_TAPS    = 32,   // number of taps
    parameter ACC_WIDTH   = 40    // accumulator width (safe margin)
)
(
    input  wire                          clk_sample,
    input  wire                          rst,
    input  wire                          valid_in,
    input  wire signed [DATA_WIDTH-1:0]  data_in,
    output reg  signed [DATA_WIDTH-1:0]  data_out,
    output reg                           valid_out
);



localparam signed [DATA_WIDTH-1:0] coeff_0_31  = 16'sd;
localparam signed [DATA_WIDTH-1:0] coeff_1_30  = 16'sd;
localparam signed [DATA_WIDTH-1:0] coeff_2_29  = 16'sd;
localparam signed [DATA_WIDTH-1:0] coeff_3_28  = 16'sd;
localparam signed [DATA_WIDTH-1:0] coeff_4_27  = 16'sd;
localparam signed [DATA_WIDTH-1:0] coeff_5_26  = 16'sd;
localparam signed [DATA_WIDTH-1:0] coeff_6_25  = 16'sd;
localparam signed [DATA_WIDTH-1:0] coeff_7_24  = 16'sd;
localparam signed [DATA_WIDTH-1:0] coeff_8_23  = 16'sd;
localparam signed [DATA_WIDTH-1:0] coeff_9_22  = 16'sd;
localparam signed [DATA_WIDTH-1:0] coeff_10_21 = 16'sd;
localparam signed [DATA_WIDTH-1:0] coeff_11_20 = 16'sd;
localparam signed [DATA_WIDTH-1:0] coeff_12_19 = 16'sd;
localparam signed [DATA_WIDTH-1:0] coeff_13_18 = 16'sd;
localparam signed [DATA_WIDTH-1:0] coeff_14_17 = 16'sd;
localparam signed [DATA_WIDTH-1:0] coeff_15_16 = 16'sd;




endmodule