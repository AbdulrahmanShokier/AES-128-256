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


localparam signed [DATA_WIDTH-1:0] one = 16'sd16384;
localparam signed [DATA_WIDTH-1:0] minus_one = -16'sd16384;



always @(posedge clk_symbol) begin
    if (!rst) begin
        data_out     <= {DATA_WIDTH{1'b0}};
        valid_out    <= 1'b0;
    end
    else begin
        valid_out <= valid_in;
        
        if (valid_in) begin
            
            data_out <= data_in ? minus_one : one;
            
        end
    end
end

endmodule