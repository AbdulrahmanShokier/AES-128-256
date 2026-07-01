module psk16_mapper #(
    parameter DATA_WIDTH = 16,
    parameter no_bits    = 4,
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

localparam signed [DATA_WIDTH-1:0] cos22     =  16'sd15136;
localparam signed [DATA_WIDTH-1:0] NEG_cos22 = -16'sd15136;

localparam signed [DATA_WIDTH-1:0] sin22     =  16'sd6269;
localparam signed [DATA_WIDTH-1:0] NEG_sin22 = -16'sd6269;


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
            4'b0000 : begin I_out <= one;               Q_out <= 16'b0;         end
            4'b1000 : begin I_out <= cos22;             Q_out <= sin22;         end
            4'b1001 : begin I_out <= SQRT2_INV;         Q_out <= SQRT2_INV;     end
            4'b1011 : begin I_out <= sin22;             Q_out <= cos22;         end
            
            4'b1010 : begin I_out <= 16'b0;             Q_out <= one;           end
            4'b1110 : begin I_out <= NEG_sin22;         Q_out <= cos22;         end
            4'b1111 : begin I_out <= NEG_SQRT2_INV;     Q_out <= SQRT2_INV;     end
            4'b1101 : begin I_out <= NEG_cos22;         Q_out <= sin22;         end
            
            4'b1100 : begin I_out <= minus_one;         Q_out <= 16'b0;         end
            4'b0100 : begin I_out <= NEG_cos22;         Q_out <= NEG_sin22;     end
            4'b0101 : begin I_out <= NEG_SQRT2_INV;     Q_out <= NEG_SQRT2_INV; end
            4'b0111 : begin I_out <= NEG_sin22;         Q_out <= NEG_cos22;     end
            
            4'b0110 : begin I_out <= 16'b0;             Q_out <= minus_one;     end
            4'b0010 : begin I_out <= sin22;             Q_out <= NEG_cos22;     end
            4'b0011 : begin I_out <= SQRT2_INV;         Q_out <= NEG_SQRT2_INV; end
            4'b0001 : begin I_out <= cos22;             Q_out <= NEG_sin22;     end
            endcase
    end
    
    else 
        begin
            I_out <= {DATA_WIDTH{1'b0}};
            Q_out <= {DATA_WIDTH{1'b0}};
        end
    end
end

endmodule