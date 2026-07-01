module psk16_DecisionDevice
(
    input  wire               clk,
    input  wire               rst,

    input  wire signed [15:0] I,
    input  wire signed [15:0] Q,

    output wire [3:0] symbol,
    output wire [15:0] angle_wave
);

wire [15:0] angle;
wire [3:0] symbol_index;

cordic_vector cordic_inst
(
    .clk(clk),
    .rst(rst),
    .x_in(I),
    .y_in(Q),
    .angle(angle)
);

assign angle_wave = angle;


sector_detector detector_inst
(
    .angle(angle),
    .index(symbol_index)
);

symbol_decoder decoder_inst
(
    .symbol_index(symbol_index),
    .symbol(symbol)
);

endmodule
