module bpsk_tx_bb_top #(
    parameter DATA_WIDTH  = 16,
    parameter FRAC_WIDTH  = 14,
    parameter COEFF_WIDTH = 16,
    parameter NUM_TAPS    = 33,
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

////////////////////////////////////////////////////////////
// Baseband Signal Pipeline Flow:
//
//  bit_valid ──► symbol_tick gate ──► bit_valid_reg
//                                         │
//  bit_in ────► symbol_tick gate ──► bit_in_reg
//                                         │
//                                    ┌────▼─────┐
//                                    │  Mapper   │
//                                    │ valid_in  │──► mapper_valid
//                                    └──────────┘         │
//                                                   ┌─────▼──────┐
//                                                   │ Upsampler  │
//                                                   │  valid_in  │──► upsample_valid
//                                                   └────────────┘         │
//                                                                    ┌─────▼─────┐
//                                                                    │    FIR    │
//                                                                    │ valid_in  │──► 
//                                                                    └───────────┘        │
//                                                                                    ┌────▼──────┐
//                                                                                    │  tx_out   │
//                                                                                    │  tx_valid │
//                                                                                    └───────────┘
//
//  Baseband output:
//    - tx_out   = pulse-shaped BPSK baseband signal (FIR output)
//    - tx_valid = FIR valid output
//    - No carrier multiplication — direct baseband
////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////
// Symbol Tick Generator (Divide by 4)
////////////////////////////////////////////////////////////

reg [1:0] symbol_cnt;

always @(posedge clk_sample)
begin
    if (!rst)
        symbol_cnt <= 2'd0;
    else
        symbol_cnt <= symbol_cnt + 1'b1;
end

wire symbol_tick = (symbol_cnt == 2'd0);

////////////////////////////////////////////////////////////
// Internal Signals
////////////////////////////////////////////////////////////

wire signed [DATA_WIDTH-1:0] mapper_out;
wire                         mapper_valid;

wire signed [DATA_WIDTH-1:0] upsample_out;
wire                         upsample_valid;

wire signed [DATA_WIDTH-1:0] fir_out;

////////////////////////////////////////////////////////////
// Symbol-rate Input Sampling
////////////////////////////////////////////////////////////

// reg bit_in_reg;
// reg bit_valid_reg;

// always @(posedge clk_sample)
// begin
//     if (!rst)
//     begin
//         bit_in_reg    <= 1'b0;
//         bit_valid_reg <= 1'b0;
//     end
//     else if (symbol_tick)
//     begin
//         bit_in_reg    <= bit_in;
//         bit_valid_reg <= bit_valid;
//     end
//     else
//     begin
//         bit_valid_reg <= 1'b0;
//     end
// end

////////////////////////////////////////////////////////////
// Mapper
////////////////////////////////////////////////////////////

bpsk_mapper #(
    .DATA_WIDTH(DATA_WIDTH),
    .FRAC_WIDTH(FRAC_WIDTH)
) mapper_inst (
    .clk_symbol (clk_sample),
    .rst        (rst),
    .valid_in   (bit_valid & symbol_tick),
    .data_in    (bit_in),
    .data_out   (mapper_out),
    .valid_out  (mapper_valid)
);

////////////////////////////////////////////////////////////
// Upsampler
////////////////////////////////////////////////////////////

bpsk_upsampler #(
    .DATA_WIDTH    (DATA_WIDTH),
    .upsample_factor(UPSAMPLE)
) upsampler_inst (
    .clk_sample (clk_sample),
    .rst        (rst),
    .valid_in   (mapper_valid),
    .data_in    (mapper_out),
    .data_out   (upsample_out),
    .valid_out  (upsample_valid)
);

////////////////////////////////////////////////////////////
// FIR Filter (Pulse Shaping)
////////////////////////////////////////////////////////////

bpsk_fir_filter #(
    .DATA_WIDTH (DATA_WIDTH),
    .COEFF_WIDTH(COEFF_WIDTH),
    .NUM_TAPS   (NUM_TAPS)
) fir_inst (
    .clk_sample (clk_sample),
    .rst        (rst),
    .data_in    (upsample_out),
    .data_out   (fir_out)
);

////////////////////////////////////////////////////////////
// Baseband Output — Direct FIR output
// No NCO, no carrier multiplication
////////////////////////////////////////////////////////////

assign tx_out   = fir_out;
assign tx_valid = upsample_valid;

endmodule