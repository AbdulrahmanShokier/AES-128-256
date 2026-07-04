module rx_system_top 
(
    input                clk,
    input                rst,
    input                valid_in,

    input  signed [15:0] I_in,
    input  signed [15:0] Q_in,

    output        [3:0]  symbol,
    output       [15:0]  angle_wave,
    output               valid_out
);

    wire signed [15:0] I_filtered;
    wire signed [15:0] Q_filtered;
    reg         [3:0]  valid_delay;

    // Matched Filter for I Channel
    matchedFilter #(
        .DATA_WIDTH(16),
        .FRAC_WIDTH(14),
        .COEFF_WIDTH(16),
        .NUM_TAPS(33)
    ) filter_i_inst (
        .clk_sample(clk),
        .rst(rst),
        .data_in(I_in),
        .data_out(I_filtered)
    );

    // Matched Filter for Q Channel
    matchedFilter #(
        .DATA_WIDTH(16),
        .FRAC_WIDTH(14),
        .COEFF_WIDTH(16),
        .NUM_TAPS(33)
    ) filter_q_inst (
        .clk_sample(clk),
        .rst(rst),
        .data_in(Q_in),
        .data_out(Q_filtered)
    );

    // Match the 4-cycle matched filter delay
    always @(posedge clk or negedge rst) 
    begin
        if (!rst) 
            valid_delay <= 4'b0;
        else 
            valid_delay <= {valid_delay[2:0], valid_in};
    end

    // Decision Device Setup
    Decision_device_16PSK_top decision_device_inst (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_delay[3]),
        .I(I_filtered),
        .Q(Q_filtered),
        .symbol(symbol),
        .angle_wave(angle_wave),
        .valid_out(valid_out)
    );

endmodule
