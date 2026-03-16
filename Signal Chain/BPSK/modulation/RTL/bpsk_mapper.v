module bpsk_mapper #(
    parameter DATA_WIDTH = 16,
    parameter FRAC_WIDTH = 14
)
(
    input  wire                         clk_symbol,
    input  wire                         rst,
    input  wire                         valid_in,
    input  wire                         data_in,    
    output reg  signed [DATA_WIDTH-1:0] data_out,
    output reg                          valid_out
);


localparam signed [DATA_WIDTH-1:0] one       = (1 << FRAC_WIDTH);
localparam signed [DATA_WIDTH-1:0] minus_one = -(1 << FRAC_WIDTH);


always @(posedge clk_sample) 
begin
    if (!rst) 
    begin
        data_out  <= {DATA_WIDTH{1'b0}};
        valid_out <= 1'b0;
    end

    else 
    begin
        valid_out <= valid_in;

        if (valid_in) 
        begin
            if (data_in)
                data_out <= NEG_ONE;    // bit 1 → -1
            else
                data_out <= POS_ONE;    // bit 0 → +1
        end

        else 
        begin
            data_out <= {DATA_WIDTH{1'b0}};
        end
    end
end

endmodule