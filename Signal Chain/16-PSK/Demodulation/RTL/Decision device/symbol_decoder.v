module symbol_decoder
(
    input  wire [3:0] symbol_index,
    output reg  [3:0] symbol
);

always @(*)
begin

    case(symbol_index)

        4'd0  : symbol = 4'b0000;
        4'd1  : symbol = 4'b1000;
        4'd2  : symbol = 4'b1001;
        4'd3  : symbol = 4'b1011;

        4'd4  : symbol = 4'b1010;
        4'd5  : symbol = 4'b1110;
        4'd6  : symbol = 4'b1111;
        4'd7  : symbol = 4'b1101;

        4'd8  : symbol = 4'b1100;
        4'd9  : symbol = 4'b0100;
        4'd10 : symbol = 4'b0101;
        4'd11 : symbol = 4'b0111;

        4'd12 : symbol = 4'b0110;
        4'd13 : symbol = 4'b0010;
        4'd14 : symbol = 4'b0011;
        4'd15 : symbol = 4'b0001;

        default : symbol = 4'b0000;

    endcase

end

endmodule
