`timescale 1ns / 1ps

module bpsk_tx_top_bb_fourones_plusrrc_tb;

////////////////////////////////////////////////////////////
// Parameters
////////////////////////////////////////////////////////////
parameter DATA_WIDTH  = 16;
parameter FRAC_WIDTH  = 14;
parameter COEFF_WIDTH = 16;
parameter NUM_TAPS    = 33;
parameter UPSAMPLE    = 4;
parameter CLK_PERIOD  = 10;

parameter PIPELINE_FLUSH = 120;

////////////////////////////////////////////////////////////
// Signals
////////////////////////////////////////////////////////////
reg                          clk_sample;
reg                          rst;
reg                          bit_valid;
reg                          bit_in;

wire signed [DATA_WIDTH-1:0] tx_out;
wire                         tx_valid;

// Matched RRC filter output (full Raised Cosine)
// No valid signal — filter runs continuously
wire signed [DATA_WIDTH-1:0] rc_out;

////////////////////////////////////////////////////////////
// File Handles for Data Export
////////////////////////////////////////////////////////////
integer file_tx_out;
integer file_rc_out;
integer file_both;
integer tx_sample_idx;
integer rc_sample_idx;

////////////////////////////////////////////////////////////
// DUT — Baseband TX (first RRC inside)
////////////////////////////////////////////////////////////
bpsk_tx_bb_top #(
    .DATA_WIDTH  (DATA_WIDTH),
    .FRAC_WIDTH  (FRAC_WIDTH),
    .COEFF_WIDTH (COEFF_WIDTH),
    .NUM_TAPS    (NUM_TAPS),
    .UPSAMPLE    (UPSAMPLE)
) dut (
    .rst        (rst),
    .clk_sample (clk_sample),
    .bit_valid  (bit_valid),
    .bit_in     (bit_in),
    .tx_out     (tx_out),
    .tx_valid   (tx_valid)
);

////////////////////////////////////////////////////////////
// Matched Filter (Second RRC) — Completes Full Raised Cosine
// RRC(TX) * RRC(RX) = RC
// No valid_in / valid_out — filter always runs
////////////////////////////////////////////////////////////
bpsk_fir_filter_mf #(
    .DATA_WIDTH  (DATA_WIDTH),
    .COEFF_WIDTH (COEFF_WIDTH),
    .NUM_TAPS    (NUM_TAPS)
) matched_filter_inst (
    .clk_sample (clk_sample),
    .rst        (rst),
    .data_in    (tx_out),
    .data_out   (rc_out)
);

////////////////////////////////////////////////////////////
// Clock Generation
////////////////////////////////////////////////////////////
initial clk_sample = 0;
always #(CLK_PERIOD/2) clk_sample = ~clk_sample;

////////////////////////////////////////////////////////////
// Test Counters and Tracking
////////////////////////////////////////////////////////////
integer pass_count;
integer fail_count;
integer tx_valid_count;
integer rc_sample_count;
integer bits_sent_count;

// Capture buffer for rc_out (full raised cosine output)
reg signed [DATA_WIDTH-1:0] rc_capture [0:4095];
integer                     capture_idx;
integer                     capture_en;

// Track sign changes on full RC output
integer sign_change_count;
reg signed [DATA_WIDTH-1:0] last_nonzero_out;

////////////////////////////////////////////////////////////
// Data Logger — Writes CSV every clock cycle
////////////////////////////////////////////////////////////
always @(posedge clk_sample) begin
    if (rst) begin
        // Combined file: log every cycle
        $fwrite(file_both, "%0d,%0d,%0b,%0d,%0b,%0b\n",
                $time,
                $signed(tx_out), tx_valid,
                $signed(rc_out),
                bit_in, bit_valid);

        // TX output: every cycle (not gated by tx_valid)
        $fwrite(file_tx_out, "%0d,%0d\n",
                tx_sample_idx, $signed(tx_out));
        tx_sample_idx = tx_sample_idx + 1;

        // RC output: every cycle
        $fwrite(file_rc_out, "%0d,%0d\n",
                rc_sample_idx, $signed(rc_out));
        rc_sample_idx = rc_sample_idx + 1;
    end
end

////////////////////////////////////////////////////////////
// Task: Send One Bit
////////////////////////////////////////////////////////////
task send_bit;
    input bit_val;
    begin
        @(posedge clk_sample);
        #1;
        while (dut.symbol_cnt !== 2'd0) begin
            @(posedge clk_sample);
            #1;
        end

        bit_in    = bit_val;
        bit_valid = 1'b1;

        @(posedge clk_sample);
        #1;

        bit_valid = 1'b0;
        bit_in    = 1'b0;

        bits_sent_count = bits_sent_count + 1;
    end
endtask

////////////////////////////////////////////////////////////
// Task: Apply Reset
////////////////////////////////////////////////////////////
task apply_reset;
    begin
        rst = 0;
        bit_valid = 0;
        bit_in    = 0;
        repeat(10) @(posedge clk_sample);
        #1;
        rst = 1;
        repeat(10) @(posedge clk_sample);
        #1;
    end
endtask

////////////////////////////////////////////////////////////
// Task: Flush Pipeline
////////////////////////////////////////////////////////////
task flush_pipeline;
    input integer num_cycles;
    begin
        repeat(num_cycles) @(posedge clk_sample);
        #1;
    end
endtask

////////////////////////////////////////////////////////////
// Task: Check Output Is Zero During Reset
////////////////////////////////////////////////////////////
task check_reset_output;
    integer k;
    integer nonzero_found;
    begin
        nonzero_found = 0;
        for (k = 0; k < 20; k = k + 1) begin
            @(posedge clk_sample);
            #1;
            if (rc_out !== 0) nonzero_found = 1;
        end

        if (!nonzero_found) begin
            $display("  PASS | RC output is zero during reset");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL | RC output not zero during reset: rc_out=%0d",
                     rc_out);
            fail_count = fail_count + 1;
        end
    end
endtask

////////////////////////////////////////////////////////////
// tx_out Monitor (pre-matched-filter)
////////////////////////////////////////////////////////////
always @(posedge clk_sample) begin
    if (tx_valid)
        tx_valid_count = tx_valid_count + 1;
end

////////////////////////////////////////////////////////////
// rc_out Monitor and Capture (always active, no valid)
////////////////////////////////////////////////////////////
always @(posedge clk_sample) begin
    if (rst) begin
        rc_sample_count = rc_sample_count + 1;

        if (capture_en && capture_idx < 4096) begin
            rc_capture[capture_idx] = rc_out;
            capture_idx = capture_idx + 1;
        end
    end
end

////////////////////////////////////////////////////////////
// Automatic sign change detector on full RC output
////////////////////////////////////////////////////////////
always @(posedge clk_sample) begin
    if (rst && rc_out !== 0) begin
        if (last_nonzero_out !== 0) begin
            if ((rc_out > 0 && last_nonzero_out < 0) ||
                (rc_out < 0 && last_nonzero_out > 0)) begin
                sign_change_count = sign_change_count + 1;
            end
        end
        last_nonzero_out = rc_out;
    end
end

////////////////////////////////////////////////////////////
// Main Test Sequence
////////////////////////////////////////////////////////////
initial begin

    // Initialize counters
    rst               = 0;
    bit_valid         = 0;
    bit_in            = 0;
    pass_count        = 0;
    fail_count        = 0;
    tx_valid_count    = 0;
    rc_sample_count   = 0;
    bits_sent_count   = 0;
    capture_idx       = 0;
    capture_en        = 0;
    sign_change_count = 0;
    last_nonzero_out  = 0;
    tx_sample_idx     = 0;
    rc_sample_idx     = 0;

    // Open CSV files for data export
    file_tx_out = $fopen("tx_out_data.csv", "w");
    file_rc_out = $fopen("rc_out_data.csv", "w");
    file_both   = $fopen("bpsk_all_data.csv", "w");

    // Write CSV headers
    $fwrite(file_tx_out, "sample,tx_out\n");
    $fwrite(file_rc_out, "sample,rc_out\n");
    $fwrite(file_both,   "time_ns,tx_out,tx_valid,rc_out,bit_in,bit_valid\n");

    //══════════════════════════════════════════════════
    // TEST 1: Reset Verification
    //══════════════════════════════════════════════════
    $display("==========================================");
    $display("   TEST 1: Reset Verification");
    $display("==========================================");

    rst = 0;
    check_reset_output;

    repeat(10) @(posedge clk_sample);
    #1;
    rst = 1;
    repeat(10) @(posedge clk_sample);
    #1;

    $display("  PASS | Reset released, DUT running");

    //══════════════════════════════════════════════════
    // TEST 2: Send Bit and Capture Full RC Output
    //══════════════════════════════════════════════════
    $display("==========================================");
    $display("   TEST 2: Full RC Output After Bit Sent");
    $display("==========================================");

    capture_en  = 1;
    capture_idx = 0;

    // Send 1 one
    send_bit(1'b1);
    send_bit(1'b1);
    send_bit(1'b0);
    send_bit(1'b1);

    #100;

    // Flush pipeline — let all data propagate through both filters
    $display("  Flushing pipeline...");
    flush_pipeline(PIPELINE_FLUSH);
    bit_valid = 1'b0;

    // Dump captured RC samples to console
    $display("  Captured %0d full-RC samples:", capture_idx);
    begin : dump_block
        integer i;
        for (i = 0; i < capture_idx && i < 64; i = i + 1) begin
            $display("    rc_capture[%0d] = %0d", i, rc_capture[i]);
        end
    end

    capture_en = 0;

    //══════════════════════════════════════════════════
    // Summary
    //══════════════════════════════════════════════════
    $display("==========================================");
    $display("   TEST SUMMARY");
    $display("==========================================");
    $display("  Total PASS: %0d", pass_count);
    $display("  Total FAIL: %0d", fail_count);
    $display("  Bits sent:         %0d", bits_sent_count);
    $display("  TX valid samples:  %0d", tx_valid_count);
    $display("  RC total samples:  %0d", rc_sample_count);
    $display("  Sign changes:      %0d", sign_change_count);
    $display("==========================================");
    $display("  Files written:");
    $display("    tx_out_data.csv   (RRC TX output)");
    $display("    rc_out_data.csv   (Full RC output)");
    $display("    bpsk_all_data.csv (All signals)");
    $display("==========================================");

    // Close all files
    $fclose(file_tx_out);
    $fclose(file_rc_out);
    $fclose(file_both);

    #100;
    $finish;
end

endmodule