module bpsk_tx_top #(
    parameter DATA_WIDTH  = 16,
    parameter FRAC_WIDTH  = 14,
    parameter COEFF_WIDTH = 16,
    parameter NUM_TAPS    = 33,
    parameter COS_WIDTH   = 16,
    parameter UPSAMPLE    = 4
)
(
    input  wire                         rst,
    input  wire                         clk_sample,

    input  wire                         bit_valid,
    input  wire                         bit_in,

    output wire signed [DATA_WIDTH-1:0] tx_out,
    output wire                         tx_valid
);


//  Symbol Tick Generator (Divide by 4)

reg [1:0] symbol_cnt;

always @(posedge clk_sample)
begin
    if (!rst)
        symbol_cnt <= 2'd0;
    else
        symbol_cnt <= symbol_cnt + 1'b1;
end

// symbol_tick asserted once every 4 cycles
wire symbol_tick = (symbol_cnt == 2'd0);

// Internal Signals

wire signed [DATA_WIDTH-1:0] mapper_out;
wire                         mapper_valid;

wire signed [DATA_WIDTH-1:0] upsample_out;
wire                         upsample_valid;

wire signed [DATA_WIDTH-1:0] fir_out;
wire                         fir_valid;

wire signed [COS_WIDTH-1:0]  nco_cos;



////////////////////////////////////////////////////////////
// Symbol-rate input sampling (VERY IMPORTANT)
////////////////////////////////////////////////////////////

reg bit_in_reg;
reg bit_valid_reg;

always @(posedge clk_sample)
begin
    if (!rst)
    begin
        bit_in_reg    <= 1'b0;
        bit_valid_reg <= 1'b0;
    end
    else if (symbol_tick)
    begin
        bit_in_reg    <= bit_in;
        bit_valid_reg <= bit_valid;
    end
    else
    begin
        bit_valid_reg <= 1'b0;  // make valid a 1-cycle pulse
    end
end

// Mapper (Now runs on sample clock)
// Only enabled every symbol_tick
// The symbol tick is high once every 4 sample clock (so it look like i used lower frequnecy by 4 times)
bpsk_mapper #(
    .DATA_WIDTH(DATA_WIDTH),
    .FRAC_WIDTH(FRAC_WIDTH)
) mapper_inst (
    .clk_symbol (clk_sample),                 // same clock now
    .rst        (rst),
    .valid_in   (bit_valid_reg),    // gated by symbol tick 
    .data_in    (bit_in_reg),
    .data_out   (mapper_out),
    .valid_out  (mapper_valid)
);

//  Upsampler
bpsk_upsampler #(
    .DATA_WIDTH(DATA_WIDTH),
    .upsample_factor(UPSAMPLE)
) upsampler_inst (
    .clk_sample (clk_sample),
    .rst        (rst),
    .valid_in   (mapper_valid),
    .data_in    (mapper_out),
    .data_out   (upsample_out),
    .valid_out  (upsample_valid)
);

//  FIR Filter
bpsk_fir_filter #(
    .DATA_WIDTH (DATA_WIDTH),
    .COEFF_WIDTH(COEFF_WIDTH),
    .NUM_TAPS   (NUM_TAPS)
) fir_inst (
    .clk_sample (clk_sample),
    .rst        (rst),
    .valid_in   (upsample_valid),
    .data_in    (upsample_out),
    .data_out   (fir_out),
    .valid_out  (fir_valid)
);

//  NCO
bpsk_nco #(
    .COS_WIDTH(COS_WIDTH)
) nco_inst (
    .rst        (rst),
    .clk_sample (clk_sample),
    .cos_value  (nco_cos)
);

//  Multiplier
bpsk_multiplier #(
    .DATA_WIDTH(DATA_WIDTH),
    .FRACTION  (FRAC_WIDTH)
) multiplier_inst (
    .rst              (rst),
    .clk_sample       (clk_sample),
    .valid_in         (fir_valid),
    .fir_data_in      (fir_out),
    .nco_cos_in       (nco_cos),
    .signal_modulated (tx_out),
    .valid_out        (tx_valid)
);

endmodule