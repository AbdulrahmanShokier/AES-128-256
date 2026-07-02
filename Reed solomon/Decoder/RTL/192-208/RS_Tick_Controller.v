`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// GitHub/DVB-style tick controller for RS integration.
// -----------------------------------------------------------------------------
// This is based on the same idea as:
//
//   reg [1:0] symbol_cnt;
//   always @(posedge clk_sample) symbol_cnt <= symbol_cnt + 1;
//   wire symbol_tick = (symbol_cnt == ...);
//
//   reg byte_cnt;
//   always @(posedge clk_sample)
//       if (symbol_tick) byte_cnt <= byte_cnt + 1;
//   wire byte_tick = ...
//
// IMPORTANT FPGA RULE:
//   - clk_sample is the ONLY clock.
//   - symbol_tick and byte_tick are NOT clocks.
//   - Do NOT use always @(posedge symbol_tick) or always @(posedge byte_tick).
//   - Use byte_tick/symbol_tick only as clock-enable strobes.
//
// In this RS version:
//   - symbol_tick pulses every 4 clk_sample cycles while run=1.
//   - byte_tick pulses every 8 clk_sample cycles while run=1.
//   - byte_tick is used to let the RS accept one 8-bit input byte.
//   - run=0 stops and resets the tick phase.
// -----------------------------------------------------------------------------
module RS_Tick_Controller (
    input  clk_sample,
    input  reset_n,
    input  run,

    output symbol_tick,  // one pulse every 4 clocks while run=1
    output byte_tick     // one pulse every 8 clocks while run=1
);

reg [1:0] symbol_cnt;
reg       byte_cnt;

// Phase choice:
//   The friend's snippet used (symbol_cnt == 0). Here we use the equivalent
//   counter idea but place the pulse at the end of the 4-clock window.
//   This makes the RS input byte stay stable for a full window before acceptance.
wire symbol_tick_int = run && (symbol_cnt == 2'd3);

assign symbol_tick = symbol_tick_int;
assign byte_tick   = symbol_tick_int && byte_cnt;

always @(posedge clk_sample) begin
    if (!reset_n) begin
        symbol_cnt <= 2'd0;
        byte_cnt   <= 1'b0;
    end else begin
        if (!run) begin
            symbol_cnt <= 2'd0;
            byte_cnt   <= 1'b0;
        end else begin
            if (symbol_cnt == 2'd3) begin
                symbol_cnt <= 2'd0;
                byte_cnt   <= byte_cnt + 1'b1;
            end else begin
                symbol_cnt <= symbol_cnt + 1'b1;
            end
        end
    end
end

endmodule
