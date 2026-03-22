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

////////////////////////////////////////////////////////////
// Valid Signal Pipeline Flow:
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
//                                                                    │ valid_in  │──► fir_valid
//                                                                    └───────────┘        │
//                                                                                    ┌────▼──────┐
//  NCO (free-running, always valid) ──► nco_cos ─────────────────────►│ Multiplier  │
//                                                                     │  valid_in   │──► tx_valid
//                                                                     └─────────────┘
//
//  Multiplier behavior:
//    - FIR data: only latched when fir_valid = 1 (held otherwise)
//    - NCO data: ALWAYS latched (free-running carrier)
//    - Output:   only updated when pipeline valid = 1
//    - Pipeline: 2-cycle latency
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
wire                         fir_valid;

wire signed [COS_WIDTH-1:0]  nco_cos;

////////////////////////////////////////////////////////////
// Symbol-rate Input Sampling
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
        bit_valid_reg <= 1'b0;
    end
end

////////////////////////////////////////////////////////////
// Mapper
////////////////////////////////////////////////////////////

bpsk_mapper #(
    .DATA_WIDTH(DATA_WIDTH),
    .FRAC_WIDTH(FRAC_WIDTH)
) mapper_inst (
    .clk_symbol (clk_sample),
    .rst        (rst),
    .valid_in   (bit_valid_reg),
    .data_in    (bit_in_reg),
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
// FIR Filter
////////////////////////////////////////////////////////////

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

////////////////////////////////////////////////////////////
// NCO — FREE RUNNING (no valid gating)
// Produces carrier cosine on EVERY clock cycle
// Always has a valid cos value ready for multiplier
////////////////////////////////////////////////////////////

bpsk_nco #(
    .COS_WIDTH(COS_WIDTH)
) nco_inst (
    .rst        (rst),
    .clk_sample (clk_sample),
    .cos_value  (nco_cos)
    // NO valid_in — runs every clock cycle ✅
);

////////////////////////////////////////////////////////////
// Multiplier — Valid-aware
// - FIR data:  latched ONLY when fir_valid = 1
// - NCO data:  ALWAYS latched (carrier is free-running)
// - Output:    updated ONLY when pipeline valid = 1
// - Latency:   2 clock cycles
////////////////////////////////////////////////////////////

bpsk_multiplier #(
    .DATA_WIDTH(DATA_WIDTH),
    .FRACTION  (FRAC_WIDTH)
) multiplier_inst (
    .rst              (rst),
    .clk_sample       (clk_sample),
    .valid_in         (fir_valid),      // ← gated by FIR valid
    .fir_data_in      (fir_out),        // ← only latched when valid
    .nco_cos_in       (nco_cos),        // ← always latched
    .signal_modulated (tx_out),         // ← updated only when valid
    .valid_out        (tx_valid)        // ← 2-cycle delayed valid
);

endmodule