module Top_module
(
    input               clk,
    input               rst,
    input               valid_in,

    input signed [15:0] I,
    input signed [15:0] Q,

    output      [3:0]   symbol,
    output     [15:0]   angle_wave,
    output reg          valid_out
);

//==========================================================
// Internal wires
//==========================================================

wire [15:0] angle;
wire [3:0] symbol_index;

//==========================================================
// Valid generation
//==========================================================

reg started;
reg [1:0] counter;

always @(posedge clk)
begin
    if(rst)
    begin
        started   <= 1'b0;
        counter   <= 2'd0;
        valid_out <= 1'b0;
    end
    else
    begin
        valid_out <= 1'b0;

        // Wait for the first valid input
        if(!started)
        begin
            if(valid_in)
            begin
                started <= 1'b1;
                counter <= 2'd0;
            end
        end
        else
        begin
            if(counter == 2'd3)
            begin
                counter   <= 2'd0;
                valid_out <= 1'b1;
            end
            else
            begin
                counter <= counter + 1'b1;
            end
        end
    end
end

//==========================================================
// CORDIC
//==========================================================

cordic_vector cordic_inst
(
    .clk(clk),
    .rst(rst),
    .x_in(I),
    .y_in(Q),
    .angle(angle)
);

assign angle_wave = angle;

//==========================================================
// Sector Detector
//==========================================================

sector_detector detector_inst
(
    .angle(angle),
    .index(symbol_index)
);

//==========================================================
// Symbol Decoder
//==========================================================

symbol_decoder decoder_inst
(
    .symbol_index(symbol_index),
    .symbol(symbol)
);

endmodule