module dvb_master_fsm (
    input  wire        clk_sample,
    input  wire        rst,
    input  wire        symbol_tick,      // one real "cycle" every 4 clk_sample ticks

    input  wire         ready_for_data,

    output reg           aes_valid,
    output reg           aes_rs_load,
    output reg           start_encode,
    output reg           rs_data_valid,
    output reg           start_parity,
    output reg           rs_mod_wr_en,
    output reg  [4:0]    cyc,
    output      [3:0]    period_count_o
);

reg [3:0] period;

wire in_rs_window;
wire is_last_period;

assign in_rs_window  = (cyc >= 5'd12) && (cyc <= 5'd27);
assign is_last_period = (period == 4'd13);

always @(posedge clk_sample) begin
    if (symbol_tick && !rst)
        cyc <= 5'd0;
    else if (symbol_tick)
        cyc <= cyc + 1'b1;
end

always @(posedge clk_sample) begin
    if (symbol_tick && !rst)
        period <= 4'd1;
    else if (symbol_tick && cyc == 5'd31) begin
        if (period == 4'd13)
            period <= 4'd1;
        else
            period <= period + 1'b1;
    end
end

always @(posedge clk_sample) begin
    if (symbol_tick && !rst) begin
        aes_valid     <= 1'b0;
        aes_rs_load   <= 1'b0;
        start_encode  <= 1'b0;
        rs_data_valid <= 1'b0;
        start_parity  <= 1'b0;
        rs_mod_wr_en  <= 1'b0;
    end
    else if (symbol_tick) begin
        // All six outputs are computed from cyc/period's value during THIS
        // tick and update once. Between ticks (the 3 idle clk_sample cycles
        // before the next symbol_tick), this branch doesn't execute, so every
        // output simply retains its last value - exactly what downstream
        // modules need, since they are gated by the same symbol_tick and only
        // ever sample on that same edge.
        aes_valid     <= (cyc == 5'd0) && !is_last_period;
        aes_rs_load   <= (cyc == 5'd11) && !is_last_period;
        start_encode  <= (cyc == 5'd9) && (period == 4'd1) && ready_for_data;
        rs_data_valid <= in_rs_window && !is_last_period;
        start_parity  <= (cyc == 5'd11) && (period == 4'd13);
        rs_mod_wr_en  <= in_rs_window;
    end
end

assign period_count_o = period;

endmodule