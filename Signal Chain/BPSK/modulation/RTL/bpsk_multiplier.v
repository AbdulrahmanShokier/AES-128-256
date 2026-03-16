module bpsk_multiplier  #(
    parameter DATA_WIDTH = 16,
    parameter FRACTION   = 14
)
(
    input                                 rst,
    input                                 clk_sample,
    input                                 valid_in,
    input      signed [DATA_WIDTH-1:0]     fir_data_in,
    input      signed [DATA_WIDTH-1:0]     nco_cos_in,
    output reg                            valid_out,
    output reg signed [DATA_WIDTH-1:0]     signal_modulated
);

// Stage 1: Input Registers
reg signed [DATA_WIDTH-1:0] a_reg, b_reg;
reg                         valid_stage1;

always @(posedge clk_sample)
begin
    if (!rst)
    begin
        a_reg        <= 0;
        b_reg        <= 0;
        valid_stage1 <= 0;
    end
    else
    begin
        a_reg        <= fir_data_in;
        b_reg        <= nco_cos_in;
        valid_stage1 <= valid_in;
    end
end


// Combinational Multiplier

wire signed [2*DATA_WIDTH-1:0] mult_comb;

assign mult_comb = a_reg * b_reg;


// Stage 2: Output Register (Scaling to Q2.14)

always @(posedge clk_sample)
begin
    if (!rst)
    begin
        signal_modulated <= 0;
        valid_out        <= 0;
    end
    else
    begin
        signal_modulated <= mult_comb >>> FRACTION;  // Q4.28 → Q2.14
        valid_out        <= valid_stage1;
    end
end

endmodule