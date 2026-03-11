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

reg [Counter_WIDTH-1:0]   counter;
reg signed [DATA_WIDTH-1:0] data_in_reg;
reg                         valid_window;  

// ── Latch input symbol ───────────────────────────────────────────
always @(posedge clk_sample) 
begin
    if (valid_in && counter == 0)
        data_in_reg <= data_in;
end

// ── valid_window control ─────────────────────────────────────────
always @(posedge clk_sample) 
begin
    if (!rst)
        valid_window <= 1'b0;
    else 
    begin
        if (valid_in && counter == 0)          // new symbol arrives
            valid_window <= 1'b1;              // start window
        else if (counter == upsample_factor-1) // last cycle of window
            valid_window <= 1'b0;              // close window
    end
end

// ── Data output ──────────────────────────────────────────────────
always @(posedge clk_sample) 
begin
    if (!rst) 
    begin
        data_out  <= {DATA_WIDTH{1'b0}};
        valid_out <= 1'b0;
    end
    else 
    begin
        valid_out <= valid_window;             // ← follows window

        if (valid_window) 
        begin
            if (counter == 0)
                data_out <= data_in_reg;
            else
                data_out <= {DATA_WIDTH{1'b0}};
        end
    end
end

// ── Counter ──────────────────────────────────────────────────────
always @(posedge clk_sample) 
begin
    if (!rst)
        counter <= {Counter_WIDTH{1'b0}};
    else
        counter <= counter + 1;                // natural overflow = modulo N
end

endmodule