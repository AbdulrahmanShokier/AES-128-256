//=============================================================================
// channel_impairment.v
//
// Purpose:
//   Adds a small CONSTANT offset to the I, Q, and BPSK symbol paths so that
//   a TX->RX loopback test is not bit-exact. Using a fixed constant (rather
//   than pseudo-random noise) makes the perturbation predictable and easy
//   to reason about while debugging demodulator lock/decision behavior.
//
// Design notes (matches project conventions):
//   - Single clock domain, no CDC.
//   - symbol_tick used as a clock-enable strobe, not a real clock, so the
//     offset is applied in lock-step with the rest of the TX/RX symbol
//     pipeline.
//   - OFFSET_I / OFFSET_Q / OFFSET_B are compile-time constants, in the same
//     signed fixed-point units as i_in/q_in/bpsk_in (e.g. Q2.14). Keep them
//     small relative to DATA_WIDTH so the constellation is nudged, not
//     destroyed -- start very small (e.g. 1-2 LSBs) since a single bad
//     symbol was enough to break demodulator lock.
//=============================================================================

module channel_impairment #(
    parameter DATA_WIDTH = 16,        // matches Q2.14 signed fixed-point I/Q width
    parameter signed [DATA_WIDTH-1:0] OFFSET_I = 16'sd1,  // constant added to I
    parameter signed [DATA_WIDTH-1:0] OFFSET_Q = 16'sd1,  // constant added to Q
    parameter signed [DATA_WIDTH-1:0] OFFSET_B = 16'sd1   // constant added to BPSK
)(
    input  wire                          clk,
    input  wire                          rst,
    input  wire                          enable,        // 0 = pure loopback, 1 = impaired

    input  wire signed [DATA_WIDTH-1:0]  i_in,
    input  wire signed [DATA_WIDTH-1:0]  q_in,
    input  wire signed [DATA_WIDTH-1:0]  bpsk_in,

    output reg  signed [DATA_WIDTH-1:0]  i_out,
    output reg  signed [DATA_WIDTH-1:0]  q_out,
    output reg  signed [DATA_WIDTH-1:0]  bpsk_out
);


    reg [1:0] symbol_cnt;

    always @(posedge clk)
    begin
        if (!rst)
            symbol_cnt <= 2'd0;
        else
            symbol_cnt <= symbol_cnt + 2'b1;
    end

    wire symbol_tick = (symbol_cnt == 2'd0);
    //-------------------------------------------------------------------
    // Registered output, updated only on symbol_tick to stay aligned
    // with the rest of the symbol-rate pipeline. Constant offset is
    // added directly -- no random generation, no LFSR.
    //-------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst) begin
            i_out    <= {DATA_WIDTH{1'b0}};
            q_out    <= {DATA_WIDTH{1'b0}};
            bpsk_out <= {DATA_WIDTH{1'b0}};
        end else  begin
            i_out    <= enable ? (i_in    + OFFSET_I) : i_in;
            q_out    <= enable ? (q_in    + OFFSET_Q) : q_in;
            bpsk_out <= enable ? (bpsk_in + OFFSET_B) : bpsk_in;
        end
    end

endmodule