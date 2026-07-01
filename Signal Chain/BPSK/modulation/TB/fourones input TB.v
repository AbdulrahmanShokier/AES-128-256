`timescale 1ns / 1ps

module bpsk_tx_top_bb_fourones_tb;

////////////////////////////////////////////////////////////
// Parameters
////////////////////////////////////////////////////////////
parameter DATA_WIDTH  = 16;
parameter FRAC_WIDTH  = 14;
parameter COEFF_WIDTH = 16;
parameter NUM_TAPS    = 33;
parameter UPSAMPLE    = 4;
parameter CLK_PERIOD  = 10;

// Pipeline latency:
// mapper(1) + upsampler(1) + FIR(4) = ~6 cycles
parameter PIPELINE_FLUSH = 30;

////////////////////////////////////////////////////////////
// Signals
////////////////////////////////////////////////////////////
reg                          clk_sample;
reg                          rst;
reg                          bit_valid;
reg                          bit_in;

wire signed [DATA_WIDTH-1:0] tx_out;
wire                         tx_valid;

////////////////////////////////////////////////////////////
// DUT — Baseband only (no NCO/carrier multiplication)
////////////////////////////////////////////////////////////
bpsk_tx_top #(
    .DATA_WIDTH (DATA_WIDTH),
    .FRAC_WIDTH (FRAC_WIDTH),
    .COEFF_WIDTH(COEFF_WIDTH),
    .NUM_TAPS   (NUM_TAPS),
    .UPSAMPLE   (UPSAMPLE)
) dut (
    .rst        (rst),
    .clk_sample (clk_sample),
    .bit_valid  (bit_valid),
    .bit_in     (bit_in),
    .tx_out     (tx_out),
    .tx_valid   (tx_valid)
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
integer bits_sent_count;

// Capture buffer for tx_out analysis
reg signed [DATA_WIDTH-1:0] tx_capture [0:4095];
integer                     capture_idx;
integer                     capture_en;

// Track sign changes (polarity flips in baseband)
integer sign_change_count;
reg signed [DATA_WIDTH-1:0] last_nonzero_out;

////////////////////////////////////////////////////////////
// Test Data
////////////////////////////////////////////////////////////
reg [15:0] test_bits;
integer    bit_index;

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

        bit_valid = 1'b1;
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
// Task: Check tx_valid Goes High After Bits Sent
////////////////////////////////////////////////////////////
task check_valid_output;
    input integer wait_cycles;
    reg found_valid;
    integer k;
    begin
        found_valid = 0;
        for (k = 0; k < wait_cycles; k = k + 1) begin
            @(posedge clk_sample);
            #1;
            if (tx_valid === 1'b1) begin
                found_valid = 1;
            end
        end

        if (found_valid) begin
            $display("  PASS | tx_valid went HIGH within %0d cycles", wait_cycles);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL | tx_valid never went HIGH in %0d cycles", wait_cycles);
            fail_count = fail_count + 1;
        end
    end
endtask

////////////////////////////////////////////////////////////
// Task: Check Baseband Sign Matches BPSK Expectation
//       Baseband output is the pulse-shaped symbol.
//       bit=1 → mapper output → FIR → expect consistent sign
//       bit=0 → mapper output → FIR → expect opposite sign
////////////////////////////////////////////////////////////
task check_baseband_sign;
    input expected_positive;  // 1=expect positive, 0=expect negative
    input integer check_cycles;
    integer positive_count;
    integer negative_count;
    integer k;
    begin
        positive_count = 0;
        negative_count = 0;

        for (k = 0; k < check_cycles; k = k + 1) begin
            @(posedge clk_sample);
            #1;
            if (tx_valid) begin
                if (tx_out > 0) positive_count = positive_count + 1;
                if (tx_out < 0) negative_count = negative_count + 1;
            end
        end

        $display("  [SIGN CHECK] Positive samples: %0d | Negative samples: %0d",
                 positive_count, negative_count);

        if (expected_positive) begin
            if (positive_count > negative_count) begin
                $display("  PASS | Baseband output is mostly POSITIVE");
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL | Expected mostly positive baseband output");
                fail_count = fail_count + 1;
            end
        end else begin
            if (negative_count > positive_count) begin
                $display("  PASS | Baseband output is mostly NEGATIVE");
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL | Expected mostly negative baseband output");
                fail_count = fail_count + 1;
            end
        end
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
            if (tx_out !== 0) nonzero_found = 1;
            if (tx_valid !== 0) nonzero_found = 1;
        end

        if (!nonzero_found) begin
            $display("  PASS | Output is zero during reset");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL | Output not zero during reset: tx_out=%0d tx_valid=%0b",
                     tx_out, tx_valid);
            fail_count = fail_count + 1;
        end
    end
endtask

////////////////////////////////////////////////////////////
// Task: Count Valid Outputs in Window
////////////////////////////////////////////////////////////
task count_valid_in_window;
    input integer window_cycles;
    output integer count;
    integer k;
    begin
        count = 0;
        for (k = 0; k < window_cycles; k = k + 1) begin
            @(posedge clk_sample);
            #1;
            if (tx_valid === 1'b1)
                count = count + 1;
        end
    end
endtask

////////////////////////////////////////////////////////////
// tx_out Monitor and Capture
////////////////////////////////////////////////////////////
always @(posedge clk_sample) begin
    if (tx_valid) begin
        tx_valid_count = tx_valid_count + 1;

        if (capture_en && capture_idx < 4096) begin
            tx_capture[capture_idx] = tx_out;
            capture_idx = capture_idx + 1;
        end
    end
end

////////////////////////////////////////////////////////////
// Automatic sign change detector
////////////////////////////////////////////////////////////
always @(posedge clk_sample) begin
    if (rst && tx_valid && tx_out !== 0) begin
        if (last_nonzero_out !== 0) begin
            if ((tx_out > 0 && last_nonzero_out < 0) ||
                (tx_out < 0 && last_nonzero_out > 0)) begin
                sign_change_count = sign_change_count + 1;
            end
        end
        last_nonzero_out = tx_out;
    end
end

////////////////////////////////////////////////////////////
// Main Test Sequence
////////////////////////////////////////////////////////////
initial begin

    // Initialize counters
    rst              = 0;
    bit_valid        = 0;
    bit_in           = 0;
    pass_count       = 0;
    fail_count       = 0;
    tx_valid_count   = 0;
    bits_sent_count  = 0;
    capture_idx      = 0;
    capture_en       = 0;
    sign_change_count= 0;
    last_nonzero_out = 0;

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
    // TEST 2: tx_valid Activates After Data Sent
    //══════════════════════════════════════════════════
    $display("==========================================");
    $display("   TEST 2: tx_valid Activates After Bits");
    $display("==========================================");

    //repeat(4) 
    send_bit(1'b1);
    check_valid_output(PIPELINE_FLUSH);
    
    
    
    end

    endmodule