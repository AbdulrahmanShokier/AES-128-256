module psk16_upsampler #(
    parameter DATA_WIDTH      = 16,
    parameter Counter_WIDTH   = 2,
    parameter upsample_factor = 4
)(
    input  wire                          clk_sample,
    input  wire                          rst,
    input  wire                          valid_in,
    input  wire signed [DATA_WIDTH-1:0]  data_in,
    output reg  signed [DATA_WIDTH-1:0]  data_out
    // valid_out removed — handled by symbol_tick in top level
);

reg [Counter_WIDTH-1:0]      counter;
reg signed [DATA_WIDTH-1:0]  data_in_reg;
reg                           valid_window;

// ── Counter ────────────────────────────────────────────────
// Resets to 0 on valid_in (symbol boundary = counter 0)
always @(posedge clk_sample)
begin
    if (!rst)
        counter <= 0;
    else
    begin
        if (valid_in)
            counter <= 0;           // ← symbol boundary marker
        else if (valid_window)
            counter <= counter + 1;
        else
            counter <= 0;
    end
end

// ── valid_window ───────────────────────────────────────────
// Ends at upsample_factor-2 (not -1) to compensate for
// counter starting at 0 → avoids 1 extra zero output
//
// Counter timeline:
// Edge 0 (valid_in): counter=0 → data_in output
// Edge 1:            counter=0 → zero (window active)
// Edge 2:            counter=1 → zero (window active)
// Edge 3:            counter=2 → zero, window CLOSES ← (upsample_factor-2)
// Total: 1 symbol + 3 zeros = 4 samples ✓
always @(posedge clk_sample)
begin
    if (!rst)
        valid_window <= 1'b0;
    else
    begin
        if (valid_in)
            valid_window <= 1'b1;
        else if (counter == upsample_factor - 2)  // ← adjusted from -1 to -2
            valid_window <= 1'b0;
    end
end

// ── Latch symbol ───────────────────────────────────────────
always @(posedge clk_sample)
begin
    if (!rst)
        data_in_reg <= {DATA_WIDTH{1'b0}};
    else if (valid_in)
        data_in_reg <= data_in;
end

// ── Output Logic ───────────────────────────────────────────
always @(posedge clk_sample)
begin
    if (!rst)
        data_out <= {DATA_WIDTH{1'b0}};
    else
    begin
        if (valid_in)
            data_out <= data_in;          // counter=0: symbol
        else if (valid_window)
            data_out <= {DATA_WIDTH{1'b0}}; // counter=0,1,2: zeros
        else
            data_out <= {DATA_WIDTH{1'b0}};
    end
end

endmodule