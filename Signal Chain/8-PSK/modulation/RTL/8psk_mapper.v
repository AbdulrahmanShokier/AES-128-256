module psk8_mapper #(
    parameter DATA_WIDTH = 16,
    parameter no_bits    = 3,
    parameter FRAC_WIDTH = 14
)
(
    input                               clk_symbol,
    input                               rst,
    input                               valid_in,
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
            3'b000 : begin I_out <= one;              Q_out <= 16'b0;         end
            3'b001 : begin I_out <= SQRT2_INV;        Q_out <= SQRT2_INV;     end
            3'b011 : begin I_out <= 16'b0;            Q_out <= one;           end
            3'b010 : begin I_out <= NEG_SQRT2_INV;    Q_out <= SQRT2_INV;     end
            3'b110 : begin I_out <= minus_one;        Q_out <= 16'b0;         end
            3'b111 : begin I_out <= NEG_SQRT2_INV;    Q_out <= NEG_SQRT2_INV; end
            3'b101 : begin I_out <= 16'b0;            Q_out <= minus_one;     end
            3'b100 : begin I_out <= SQRT2_INV;        Q_out <= NEG_SQRT2_INV; end
            endcase
    end
    end
end

endmodule