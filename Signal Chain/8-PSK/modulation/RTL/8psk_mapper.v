module 8psk_mapper #(
    parameter DATA_WIDTH = 16,
    parameter no_bits    = 3,
    parameter FRAC_WIDTH = 14
)
(
    input  wire                         clk_symbol,
    input  wire                         rst,
    input  wire                         valid_in,
    input  wire        [no_bits-1 : 0]  data_in,    

    output reg  signed [DATA_WIDTH-1:0] I_out,
    output reg  signed [DATA_WIDTH-1:0] Q_out,
    output reg                          valid_out
);


localparam signed [DATA_WIDTH-1:0] one       =  (1 << FRAC_WIDTH);
localparam signed [DATA_WIDTH-1:0] minus_one = -(1 << FRAC_WIDTH);

localparam signed [DATA_WIDTH-1:0] SQRT2_INV     =  16'sd11585;
localparam signed [DATA_WIDTH-1:0] NEG_SQRT2_INV = -16'sd11585;


always @(posedge clk_symbol) 
begin
    if (!rst) 
    begin
        I_out  <= {DATA_WIDTH{1'b0}};
        Q_out  <= {DATA_WIDTH{1'b0}};
        valid_out <= 1'b0;
    end

    else 
    begin
        valid_out <= valid_in;

        if (valid_in) 
        begin
            case(data_in)
            3'b000 : I_out <= 16'b0;            Q_out <= 16'b0;
            3'b001 : I_out <= SQRT2_INV;        Q_out <= SQRT2_INV;
            3'b011 : I_out <= 16'b0;            Q_out <= one;
            3'b010 : I_out <= NEG_SQRT2_INV;    Q_out <= SQRT2_INV;
            3'b110 : I_out <= minus_one;        Q_out <= 16'b0;
            3'b111 : I_out <= NEG_SQRT2_INV;    Q_out <= NEG_SQRT2_INV;
            3'b101 : I_out <= 16'b0;            Q_out <= minus_one
            3'b100 : I_out <= SQRT2_INV;        Q_out <= NEG_SQRT2_INV;
            endcase
    end
    end
end

endmodule