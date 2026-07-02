`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// Top-level RS(208,192) decoder.
// Input:  one received 8-bit symbol per clock while enable=1.
// Output: 192 corrected data symbols, one per clock while out_valid=1.
// reset is active-low.
// -----------------------------------------------------------------------------
module Top_decoder (
    input        clock,
    input        reset,

    // Source-valid / stop control:
    // Hold enable=1 while the source is sending a frame.
    // The internal GitHub-style byte_tick lets the RS accept one byte every
    // 8 clocks. Drive enable=0 to stop/reset the input tick phase.
    input        enable,
    input  [7:0] received_symbol,

    // Debug/integration ticks:
    // input_symbol_tick:  one accepted input byte every 8 clocks while enable=1.
    // output_symbol_tick: one output byte strobe every 4 clocks during output.
    output       input_symbol_tick,
    output       output_symbol_tick,

    output       out_valid,
    output [7:0] Cx,
    output       decode_fail,
    output       decode_failed,
    output       decoder_ready,
    output       frame_done,

    // Debug-only signals for waveform verification:
    output       decoder_step_tick_dbg,
    output [1:0] decoder_4clk_phase_dbg,
    output [15:0] decoder_step_count_dbg
);

localparam TOP_N = 208;

wire decode_fail_internal;
wire frame_done_internal;

reg        processing_busy;
reg [8:0]  top_rx_count;

wire [127:0] syndromes;
wire         syndromes_ready;

wire [71:0] lambda;
wire [5:0]  num_errors;
wire        bm_done;
wire        bm_uncorrectable;

wire        error_found;
wire [7:0]  Xi;
wire [7:0]  alpha_power;
wire [5:0]  chien_error_count;
wire        chien_done;

wire input_4clk_symbol_tick;
wire decoder_step_tick;
wire unused_decoder_byte_tick;

reg bm_start_pending;
reg [15:0] decoder_step_count_reg;
wire bm_start = bm_start_pending && decoder_step_tick;

RS_Tick_Controller U_INPUT_TICKS (
    .clk_sample  (clock),
    .reset_n     (reset),
    .run         (enable && decoder_ready),
    .symbol_tick (input_4clk_symbol_tick),
    .byte_tick   (input_symbol_tick)
);

// Internal decoder processing/output step tick.
// This is the same 4-clock rhythm as the output pacing.
// It is NOT a clock. It is only a clock-enable used to make BM, Chien,
// Forney correction, and output advance once every 4 main clocks.
RS_Tick_Controller U_DECODER_STEP_TICKS (
    .clk_sample  (clock),
    .reset_n     (reset),
    .run         (processing_busy),
    .symbol_tick (decoder_step_tick),
    .byte_tick   (unused_decoder_byte_tick)
);

// RS core accepts an 8-bit byte only on the 8-clock byte tick.
wire core_enable = enable && decoder_ready && input_symbol_tick;

// TOP input frame busy/ready control.
// decoder_ready stays high while the block is idle or receiving the current frame.
// After the 208th accepted byte, decoder_ready goes low until frame_done returns
// from the Forney/output block. This prevents a new frame from overwriting the
// single internal frame buffer while decode/output is still running.
assign decoder_ready = !processing_busy;
assign frame_done    = frame_done_internal;

// Debug waveform signals. These do not affect functionality.
assign decoder_step_tick_dbg  = decoder_step_tick;
assign decoder_4clk_phase_dbg = U_DECODER_STEP_TICKS.symbol_cnt;
assign decoder_step_count_dbg = decoder_step_count_reg;

always @(posedge clock) begin
    if (!reset) begin
        processing_busy  <= 1'b0;
        top_rx_count     <= 9'd0;
        bm_start_pending <= 1'b0;
        decoder_step_count_reg <= 16'd0;
    end else begin
        if (frame_done_internal) begin
            processing_busy  <= 1'b0;
            top_rx_count     <= 9'd0;
            bm_start_pending <= 1'b0;
            decoder_step_count_reg <= 16'd0;
        end else begin
            // Syndrome_ready is a one-clock pulse from the input side.
            // Latch it until the next 4-clock decoder_step_tick so BM does
            // not start on a fast main-clock cycle.
            if (syndromes_ready)
                bm_start_pending <= 1'b1;
            else if (bm_start)
                bm_start_pending <= 1'b0;

            if (processing_busy && decoder_step_tick)
                decoder_step_count_reg <= decoder_step_count_reg + 1'b1;

            if (core_enable) begin
                if (top_rx_count == TOP_N-1) begin
                    top_rx_count    <= 9'd0;
                    processing_busy <= 1'b1;
                end else begin
                    top_rx_count <= top_rx_count + 1'b1;
                end
            end
        end
    end
end


Syndrome U1 (
    .clk              (clock),
    .reset            (reset),
    .enable           (core_enable),
    .received_symbol  (received_symbol),
    .syndromes        (syndromes),
    .syndromes_ready  (syndromes_ready)
);

B_M_Algorithm U2 (
    .clk       (clock),
    .reset     (reset),
    .clk_en    (decoder_step_tick),
    .start     (bm_start),
    .syndromes (syndromes),
    .lambda        (lambda),
    .L             (num_errors),
    .done          (bm_done),
    .uncorrectable (bm_uncorrectable)
);

Chien_Search U4 (
    .clk          (clock),
    .reset        (reset),
    .clk_en       (decoder_step_tick),
    .start        (bm_done),
    .lambda       (lambda),
    .L            (num_errors),
    .error_found  (error_found),
    .xi           (Xi),
    .alpha_power  (alpha_power),
    .error_count  (chien_error_count),
    .done         (chien_done)
);

Forney_Algorithm U5 (
    .clk             (clock),
    .reset           (reset),
    .proc_en         (decoder_step_tick),
    .rec_en          (core_enable),
    .Rx              (received_symbol),
    .chien_start     (bm_done),
    .error_found_en  (error_found),
    .Xi              (Xi),
    .alpha_power     (alpha_power),
    .chien_done      (chien_done),
    .num_errors      (num_errors),
    .bm_uncorrectable(bm_uncorrectable),
    .syndromes       (syndromes),
    .lambda          (lambda),
    .out_valid       (out_valid),
    .Cx              (Cx),
    .decode_fail     (decode_fail_internal),
    .frame_done       (frame_done_internal),
    .output_symbol_tick(output_symbol_tick)
);

// Both output names are provided for integration compatibility.
assign decode_fail   = decode_fail_internal;
assign decode_failed = decode_fail_internal;

endmodule
