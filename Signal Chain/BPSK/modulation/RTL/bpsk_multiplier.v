module bpsk_multiplier #(
    parameter DATA_WIDTH = 16,
    parameter FRACTION   = 14
)
(
    input                                  rst,
    input                                  clk_sample,
    input      signed [DATA_WIDTH-1:0]     fir_data_in,
    input      signed [DATA_WIDTH-1:0]     nco_cos_in,
    output reg signed [DATA_WIDTH-1:0]     signal_modulated
);

// ═══════════════════════════════════════════════════════
// Stage 1: Input Registers
// ═══════════════════════════════════════════════════════
// FIR data: only latch when valid (hold otherwise)
// NCO data: always latch (NCO is free-running, always valid)
// ═══════════════════════════════════════════════════════

reg signed [DATA_WIDTH-1:0] fir_reg;
reg signed [DATA_WIDTH-1:0] nco_reg;

always @(posedge clk_sample)
begin
    if (!rst)
    begin
        fir_reg      <= 0;
        nco_reg      <= 0;
    end
    else
    begin
        // NCO is free-running → always latch latest cosine
        nco_reg      <= nco_cos_in;

        // FIR data → only latch when valid
        
            fir_reg <= fir_data_in;

        // Pipeline valid signal
        
    end
end

// ═══════════════════════════════════════════════════════
// Combinational Multiplier
// ═══════════════════════════════════════════════════════

wire signed [2*DATA_WIDTH-1:0] mult_comb;

assign mult_comb = fir_reg * nco_reg;

// ═══════════════════════════════════════════════════════
// Stage 2: Output Register (Scaling Q4.28 → Q2.14)
// ═══════════════════════════════════════════════════════

always @(posedge clk_sample)
begin
    if (!rst)
    begin
        signal_modulated <= 0;
    end
    else
    begin
        // update output 
            signal_modulated <= mult_comb >>> FRACTION;

    end
end

endmodule