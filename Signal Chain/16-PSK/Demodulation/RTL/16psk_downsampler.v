module psk16_downsmapler #(
    parameter DATA_WIDTH  = 16  // input/output width
)
(
    input  wire                          clk_sample,
    input  wire                          rst,
    input  wire signed [DATA_WIDTH-1:0]  data_in,
    input  wire                          sample,
    
    output reg  signed [DATA_WIDTH-1:0]  data_out
);



always @(posedge clk_sample)
begin
    if (!rst)
        data_out <= 0;
    else if(sample)
    begin
        data_out <= data_in;
    end
end

endmodule
