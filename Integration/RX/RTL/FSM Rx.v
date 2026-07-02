module Rx_ctrl_fsm #(
    parameter FEED_BYTES  = 208,
    parameter FEED_CNT_W  = 8,
    parameter LATENCY     = 224,   // 2 + 222 (symbol_ticks)
    parameter OUT_LEN     = 192,
    parameter TICK_CNT_W  = 9,     // covers 0..415
    parameter NUM_WORDS   = 12,
    parameter NUM_BATCHES = 4,     // total 208-byte batches in one full frame
    parameter BATCH_CNT_W = 8
)
(
    input        clk_sample,
    input        rst,
    input        symbol_tick,
    input        valid,            // ONE-SHOT pulse: kicks off the whole frame
    input        decode_fail_A,
    input        decode_fail_B,
    input        word_tick,        // from rs_aes_reg: pulses when a 128-bit word completes

    output       enable_A,
    output       enable_B,
    output reg   load,
    output reg   aes_valid,
    output       nibble_batch_done_o
);

localparam IDLE  = 2'd0;
localparam DEC_A = 2'd1;
localparam DEC_B = 2'd2;
localparam DRAIN = 2'd3;
localparam NIBBLE_TOTAL = FEED_BYTES * 2;   // 416

reg [1:0]             state;
reg [TICK_CNT_W-1:0]  nibble_cnt;
reg [TICK_CNT_W-1:0]  tick_cnt;
reg [3:0]             word_idx;
reg                   drain_src_is_A;
reg [BATCH_CNT_W-1:0] batch_cnt;      // counts completed batches, 0..NUM_BATCHES-1

wire feed_done   = symbol_tick && (nibble_cnt == NIBBLE_TOTAL - 1);
wire drain_done  = symbol_tick && (tick_cnt == LATENCY + OUT_LEN - 1);
wire last_batch  = (batch_cnt == NUM_BATCHES - 1);

assign nibble_batch_done_o = feed_done;

// ---------------- state register ----------------
always @(posedge clk_sample) begin
    if (!rst)
        state <= IDLE;
    else case (state)
        IDLE : if (valid)     state <= DEC_A;
        DEC_A: if (feed_done) state <= last_batch ? DRAIN : DEC_B;
        DEC_B: if (feed_done) state <= last_batch ? DRAIN : DEC_A;
        DRAIN: if (drain_done) state <= IDLE;
        default: state <= IDLE;
    endcase
end

// ---------------- batch counter ----------------
always @(posedge clk_sample) begin
    if (!rst || state == IDLE)
        batch_cnt <= {BATCH_CNT_W{1'b0}};
    else if (feed_done && !last_batch)
        batch_cnt <= batch_cnt + 1'b1;
end

// latch which decoder is finishing up, right as we enter DRAIN
always @(posedge clk_sample) begin
    if (!rst)
        drain_src_is_A <= 1'b0;
    else if ((state == DEC_A) && feed_done && last_batch)
        drain_src_is_A <= 1'b1;
    else if ((state == DEC_B) && feed_done && last_batch)
        drain_src_is_A <= 1'b0;
end

assign enable_A = (state == DEC_A);
assign enable_B = (state == DEC_B);

// ---------------- nibble counter ----------------
always @(posedge clk_sample) begin
    if (!rst || state == IDLE)
        nibble_cnt <= {TICK_CNT_W{1'b0}};
    else if (symbol_tick && (state == DEC_A || state == DEC_B))
        nibble_cnt <= feed_done ? {TICK_CNT_W{1'b0}} : nibble_cnt + 1'b1;
end

// ---------------- output/latency tick counter ----------------
always @(posedge clk_sample) begin
    if (!rst || state == IDLE)
        tick_cnt <= {TICK_CNT_W{1'b0}};
    else if (symbol_tick) begin
        if (state == DRAIN)
            tick_cnt <= drain_done ? {TICK_CNT_W{1'b0}} : tick_cnt + 1'b1;
        else
            tick_cnt <= feed_done ? {TICK_CNT_W{1'b0}} : tick_cnt + 1'b1;
    end
end

wire in_out_win    = (tick_cnt >= LATENCY) && (tick_cnt < LATENCY + OUT_LEN);
wire out_win_start = symbol_tick && (tick_cnt == LATENCY);

// ---------------- load: feeds rs_aes_reg while the "other" decoder outputs ----------------
always @(posedge clk_sample) begin
    if (!rst)
        load <= 1'b0;
    else
        load <= symbol_tick && in_out_win && (state != IDLE);
end

// ---------------- which decoder is currently outputting (covers DRAIN too) ----------------
wire outputting_is_A = (state == DEC_B) || (state == DRAIN &&  drain_src_is_A);
wire outputting_is_B = (state == DEC_A) || (state == DRAIN && !drain_src_is_A);

// ---------------- latch fail flag once, right when output starts ----------------
reg fail_latched;
always @(posedge clk_sample) begin
    if (!rst)
        fail_latched <= 1'b0;
    else if (out_win_start)
        fail_latched <= (outputting_is_A && decode_fail_A) ||
                         (outputting_is_B && decode_fail_B);
end

// ---------------- word index within the 12-word output burst ----------------
always @(posedge clk_sample) begin
    if (!rst || state == IDLE)
        word_idx <= 4'd0;
    else if (word_tick)
        word_idx <= word_idx + 1'b1;
end

// ---------------- aes_valid: one pulse per completed word, gated by latched fail ----------------
always @(posedge clk_sample) begin
    if (!rst)
        aes_valid <= 1'b0;
    else
        aes_valid <= word_tick && (word_idx < NUM_WORDS) && !fail_latched;
end

endmodule