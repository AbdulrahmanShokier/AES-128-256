//==============================================================================
// Module: bpsk_modulator
// Description: bPSK modulator with fixed-point arithmetic
// Format: Q2.14 (16-bit signed: 1 sign + 2 integer + 14 fractional)
// FIXED: Swapped I/Q bit assignments to match testbench expectations
//==============================================================================
module bpsk_mapper #(
    parameter DATA_WIDTH = 16,
    parameter FRAC_WIDTH = 14
)
(
    input  wire                     clk_symbol,
    input  wire                     rst,
    input  wire                     valid_in,
    input  wire                     data_in,    
    output reg  signed [DATA_WIDTH-1:0] data_out,
    output reg                      valid_out
);

//==============================================================================
// Fixed-Point Constants
//==============================================================================
localparam signed [DATA_WIDTH-1:0] one = 16'sd16384;
localparam signed [DATA_WIDTH-1:0] minus_one = -16'sd16384;

//==============================================================================
// BPSK Mapping Logic
//   0 → (+1) = 0°
//   1 → (-1) = 180°

//==============================================================================

always @(posedge clk_symbol) begin
    if (!rst) begin
        data_out     <= {DATA_WIDTH{1'b0}};
        valid_out    <= 1'b0;
    end
    else begin
        valid_out <= valid_in;
        
        if (valid_in) begin
            // I channel: bit=0 → positive, bit=1 → negative
            data_out <= data_in ? minus_one : one;
            
        end
    end
end

endmodule