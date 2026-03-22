module bpsk_upsampler #(
    parameter DATA_WIDTH      = 16,
    parameter Counter_WIDTH   = 2,
    parameter upsample_factor = 4
)
(
    input  wire                          clk_sample,
    input  wire                          rst,
    input  wire                          valid_in,
    input  wire signed [DATA_WIDTH-1:0]  data_in,
    output reg  signed [DATA_WIDTH-1:0]  data_out,
    output reg                           valid_out
);

reg [Counter_WIDTH:0]        counter;

// ═══════════════════════════════════════════════════
// KEY FIX: data_in_reg is a REGISTER that holds
// the symbol but we bypass it combinationally
// on the FIRST cycle using valid_in directly
// ═══════════════════════════════════════════════════
reg signed [DATA_WIDTH-1:0]  data_in_reg;
reg                           valid_window;

// ── Counter ────────────────────────────────────────
always @(posedge clk_sample)
begin
    if (!rst)
        counter <= 0;
    else
    begin
        if (valid_in)
            // Reset counter on new valid
            // Works for both fresh and back-to-back
            counter <= 1;  // ← starts at 1 because
                           //   cycle 0 is THIS cycle

        else if (valid_window)
        begin
            if (counter == upsample_factor - 1)
                counter <= 0;
            else
                counter <= counter + 1;
        end
        else
            counter <= 0;
    end
end

// ── valid_window ───────────────────────────────────
always @(posedge clk_sample)
begin
    if (!rst)
        valid_window <= 1'b0;
    else
    begin
        if (valid_in)
            valid_window <= 1'b1;
        else if (valid_window && counter == upsample_factor - 1)
            valid_window <= 1'b0;
    end
end

// ── Latch symbol for cycles 1,2,3 ─────────────────
always @(posedge clk_sample)
begin
    if (!rst)
        data_in_reg <= {DATA_WIDTH{1'b0}};
    else if (valid_in)
        data_in_reg <= data_in;
end

// ── Output Logic ───────────────────────────────────
// ═══════════════════════════════════════════════════
// SINGLE register stage:
// Cycle 0 (valid_in=1):  output data_in DIRECTLY
//                        (bypass data_in_reg)
// Cycle 1,2,3:           output zeros
// ═══════════════════════════════════════════════════
always @(posedge clk_sample)
begin
    if (!rst)
    begin
        data_out  <= {DATA_WIDTH{1'b0}};
        valid_out <= 1'b0;
    end
    else
    begin
        valid_out <= valid_window | valid_in;
        //           ↑              ↑
        //           ongoing window  first cycle

        if (valid_in)
            // ══════════════════════════════════════
            // Cycle 0: Use data_in DIRECTLY
            // This is the bypass — only 1 register
            // between input and output ✅
            // ══════════════════════════════════════
            data_out <= data_in;

        else if (valid_window)
            // Cycles 1,2,3: output zeros
            data_out <= {DATA_WIDTH{1'b0}};

        else
            data_out <= {DATA_WIDTH{1'b0}};
    end
end

endmodule