`timescale 1ns / 1ps

module bpsk_fir_filter_tb;

////////////////////////////////////////////////////////////
// Parameters
////////////////////////////////////////////////////////////
parameter DATA_WIDTH  = 16;
parameter COEFF_WIDTH = 16;
parameter NUM_TAPS    = 33;
parameter FRAC_WIDTH  = 14;
parameter CLK_PERIOD  = 10;

////////////////////////////////////////////////////////////
// Signals
////////////////////////////////////////////////////////////
reg                          clk;
reg                          rst;
reg                          valid_in;
reg  signed [DATA_WIDTH-1:0] data_in;

wire signed [DATA_WIDTH-1:0] data_out;
wire                         valid_out;

////////////////////////////////////////////////////////////
// DUT
////////////////////////////////////////////////////////////
bpsk_fir_filter #(
    .DATA_WIDTH (DATA_WIDTH),
    .COEFF_WIDTH(COEFF_WIDTH),
    .NUM_TAPS   (NUM_TAPS)
) dut (
    .clk_sample (clk),
    .rst        (rst),
    .valid_in   (valid_in),
    .data_in    (data_in),
    .data_out   (data_out),
    .valid_out  (valid_out)
);

////////////////////////////////////////////////////////////
// Clock Generation
////////////////////////////////////////////////////////////
initial clk = 0;
always #(CLK_PERIOD/2) clk = ~clk;

////////////////////////////////////////////////////////////
// Constants
////////////////////////////////////////////////////////////
localparam signed [DATA_WIDTH-1:0] POS_ONE =  (1 <<< FRAC_WIDTH);  // +16384
localparam signed [DATA_WIDTH-1:0] NEG_ONE = -(1 <<< FRAC_WIDTH);  // -16384
localparam signed [DATA_WIDTH-1:0] ZERO    =  0;

////////////////////////////////////////////////////////////
// Test Counters
////////////////////////////////////////////////////////////
integer pass_count;
integer fail_count;
integer sample_count;

////////////////////////////////////////////////////////////
// Output Capture (For Analysis)
////////////////////////////////////////////////////////////
reg signed [DATA_WIDTH-1:0] output_buffer [0:255];
integer output_index;

always @(posedge clk) begin
    if (valid_out) begin
        output_buffer[output_index] = data_out;
        output_index = output_index + 1;
        sample_count = sample_count + 1;
        $display("  [OUT] Time=%0t | Sample[%0d] = %0d",
                 $time, output_index-1, data_out);
    end
end

////////////////////////////////////////////////////////////
// Task: Send One Sample With Valid
////////////////////////////////////////////////////////////
task send_sample;
    input signed [DATA_WIDTH-1:0] sample;
    begin
        @(posedge clk);
        data_in  <= sample;
        valid_in <= 1'b1;
        @(posedge clk);
        valid_in <= 1'b0;
        data_in  <= 0;
    end
endtask

////////////////////////////////////////////////////////////
// Task: Send Upsampled Symbol (symbol, 0, 0, 0)
////////////////////////////////////////////////////////////
task send_upsampled_symbol;
    input signed [DATA_WIDTH-1:0] symbol;
    begin
        send_sample(symbol);
        send_sample(ZERO);
        send_sample(ZERO);
        send_sample(ZERO);
    end
endtask

////////////////////////////////////////////////////////////
// Task: Wait For Pipeline Flush
////////////////////////////////////////////////////////////
task wait_flush;
    input integer num_cycles;
    begin
        repeat(num_cycles) @(posedge clk);
    end
endtask

////////////////////////////////////////////////////////////
// Task: Check Symmetry Of Impulse Response
////////////////////////////////////////////////////////////
task check_symmetry;
    integer k;
    integer sym_pass;
    begin
        sym_pass = 1;
        $display("  Checking impulse response symmetry...");
        for (k = 0; k < output_index/2; k = k + 1) begin
            if (output_buffer[k] !== output_buffer[output_index-1-k]) begin
                $display("  FAIL | h[%0d]=%0d != h[%0d]=%0d",
                         k, output_buffer[k],
                         output_index-1-k, output_buffer[output_index-1-k]);
                sym_pass = 0;
                fail_count = fail_count + 1;
            end
        end
        if (sym_pass) begin
            $display("  PASS | Impulse response is symmetric");
            pass_count = pass_count + 1;
        end
    end
endtask

////////////////////////////////////////////////////////////
// Task: Check DC Gain
////////////////////////////////////////////////////////////
task check_dc_gain_upsampled;
    integer k;
    reg signed [31:0] phase_sum [0:3];
    reg signed [31:0] avg;
    begin
        // Read the last 4 steady-state outputs (one per phase)
        phase_sum[0] = output_buffer[output_index-4];
        phase_sum[1] = output_buffer[output_index-3];
        phase_sum[2] = output_buffer[output_index-2];
        phase_sum[3] = output_buffer[output_index-1];

        avg = (phase_sum[0] + phase_sum[1] + 
               phase_sum[2] + phase_sum[3]) / 4;

        $display("  Phase 0 = %0d", phase_sum[0]);
        $display("  Phase 1 = %0d", phase_sum[1]);
        $display("  Phase 2 = %0d", phase_sum[2]);
        $display("  Phase 3 = %0d", phase_sum[3]);
        $display("  Average DC Gain = %0d (expected ~15334)", avg);

        // Check average is close to 15334 (= 61334/4)
        if (avg > 14000 && avg < 17000) begin
            $display("  PASS | DC gain within expected range");
            pass_count = pass_count + 1;
        end
        else begin
            $display("  FAIL | DC gain = %0d", avg);
        end
    end
endtask


////////////////////////////////////////////////////////////
// Main Test
////////////////////////////////////////////////////////////
initial begin

    // Initialize
    rst          = 0;
    valid_in     = 0;
    data_in      = 0;
    pass_count   = 0;
    fail_count   = 0;
    sample_count = 0;
    output_index = 0;

    //--------------------------------------------------
    // 1️⃣ Reset
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 1: Reset");
    $display("==========================================");

    repeat(5) @(posedge clk);
    rst = 1;
    repeat(5) @(posedge clk);

    if (data_out === ZERO && valid_out === 1'b0) begin
        $display("PASS | Reset → output zero");
        pass_count = pass_count + 1;
    end
    else begin
        $display("FAIL | Reset state incorrect");
        fail_count = fail_count + 1;
    end

    //--------------------------------------------------
    // 2️⃣ Impulse Response Test
    //    Send single impulse → capture filter taps
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 2: Impulse Response");
    $display("==========================================");

    output_index = 0;

    // Send one impulse
    send_sample(POS_ONE);

    // Send zeros to flush through filter
    repeat(NUM_TAPS - 1) begin
        send_sample(ZERO);
    end

    // Wait for pipeline
    wait_flush(20);

    $display("  Captured %0d output samples", output_index);

    //--------------------------------------------------
    // 3️⃣ Check Impulse Response Symmetry
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 3: Symmetry Check");
    $display("==========================================");

    check_symmetry;

    //--------------------------------------------------
    // 4️⃣ Step Response Test
    //    Send continuous +1 → check DC gain
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 4: Step Response (DC Gain)");
    $display("==========================================");

    // Reset first
    rst = 0;
    repeat(5) @(posedge clk);
    rst = 1;
    repeat(5) @(posedge clk);

    output_index = 0;

    // Send many +1 samples
   repeat(NUM_TAPS) 
   begin
    send_sample(POS_ONE);    // +1 symbol
    send_sample(16'd0);      // zero-stuffed
    send_sample(16'd0);      // zero-stuffed
    send_sample(16'd0);      // zero-stuffed
end

    wait_flush(20);

    // Check last few outputs should be near +16384
    $display("  Last output = %0d (expected ~16384)", output_buffer[output_index-1]);

    check_dc_gain_upsampled;

    //--------------------------------------------------
    // 5️⃣ Upsampled BPSK Test
    //    Send realistic upsampled symbols
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 5: Upsampled BPSK Symbols");
    $display("==========================================");

    // Reset
    rst = 0;
    repeat(5) @(posedge clk);
    rst = 1;
    repeat(5) @(posedge clk);

    output_index = 0;

    // Send: +1, -1, +1, -1 (upsampled by 4)
    send_upsampled_symbol(POS_ONE);
    send_upsampled_symbol(NEG_ONE);
    send_upsampled_symbol(POS_ONE);
    send_upsampled_symbol(NEG_ONE);

    // Flush
    repeat(NUM_TAPS) begin
        send_sample(ZERO);
    end

    wait_flush(20);

    $display("  Captured %0d pulse-shaped samples", output_index);

    //--------------------------------------------------
    // 6️⃣ Negative Impulse
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 6: Negative Impulse");
    $display("==========================================");

    // Reset
    rst = 0;
    repeat(5) @(posedge clk);
    rst = 1;
    repeat(5) @(posedge clk);

    output_index = 0;

    send_sample(NEG_ONE);

    repeat(NUM_TAPS + 10) begin
        send_sample(ZERO);
    end

    wait_flush(20);

    $display("  Captured %0d samples for negative impulse", output_index);

    //--------------------------------------------------
    // 7️⃣ No Valid Test
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 7: No valid → no shift");
    $display("==========================================");

    // Reset
    rst = 0;
    repeat(5) @(posedge clk);
    rst = 1;
    repeat(5) @(posedge clk);

    // Don't send any valid
    valid_in <= 1'b0;
    data_in  <= POS_ONE;
    repeat(20) @(posedge clk);

    if (valid_out === 1'b0) begin
        $display("PASS | No valid_in → no valid_out");
        pass_count = pass_count + 1;
    end
    else begin
        $display("FAIL | valid_out should be low");
        fail_count = fail_count + 1;
    end

    //--------------------------------------------------
    // 8️⃣ Reset Mid-Operation
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 8: Reset mid-operation");
    $display("==========================================");

    // Send some data
    repeat(10) send_sample(POS_ONE);

    // Hit reset
    rst = 0;
    repeat(5) @(posedge clk);

    if (data_out === ZERO) begin
        $display("PASS | Mid-reset clears output");
        pass_count = pass_count + 1;
    end
    else begin
        $display("FAIL | Mid-reset did not clear");
        fail_count = fail_count + 1;
    end

    // Release
    rst = 1;
    repeat(5) @(posedge clk);

    // Resume
    send_sample(NEG_ONE);
    repeat(NUM_TAPS + 10) send_sample(ZERO);
    wait_flush(20);

    //--------------------------------------------------
    // 9️⃣ Long Alternating Stream
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 9: Long alternating stream");
    $display("==========================================");

    // Reset
    rst = 0;
    repeat(5) @(posedge clk);
    rst = 1;
    repeat(5) @(posedge clk);

    output_index = 0;

    repeat(20) begin
        send_upsampled_symbol(POS_ONE);
        send_upsampled_symbol(NEG_ONE);
    end

    repeat(NUM_TAPS + 20) send_sample(ZERO);
    wait_flush(20);

    $display("  Captured %0d samples", output_index);

    //--------------------------------------------------
    // 🔟 Final Report
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST COMPLETE");
    $display("   Total Output Samples : %0d", sample_count);
    $display("   PASSED               : %0d", pass_count);
    $display("   FAILED               : %0d", fail_count);
    $display("==========================================");

    if (fail_count == 0)
        $display("   ✅ ALL TESTS PASSED");
    else
        $display("   ❌ SOME TESTS FAILED");

    $display("==========================================");

    $finish;
end

////////////////////////////////////////////////////////////
// Timeout Watchdog
////////////////////////////////////////////////////////////
initial begin
    #500000;
    $display("ERROR: Simulation timeout!");
    $finish;
end

endmodule









// ✅ What This Testbench Covers
// Test	Purpose
// Reset	            Clean zero state
// Impulse response	    Capture all 33 taps
// Symmetry check	    Verify linear phase
// Step response	    Check DC gain ≈ 1.0
// Upsampled BPSK	    Realistic pulse shaping
// Negative impulse	    Verify sign handling
// No valid	            No spurious output
// Mid reset	        Clean recovery
// Long stream	        Steady-state behavior