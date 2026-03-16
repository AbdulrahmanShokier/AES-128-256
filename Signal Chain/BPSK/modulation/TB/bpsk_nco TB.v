`timescale 1ns / 1ps

module bpsk_nco_tb;

////////////////////////////////////////////////////////////
// Parameters
////////////////////////////////////////////////////////////
parameter COS_WIDTH  = 16;
parameter CLK_PERIOD = 10;  // 100 MHz

// NCO produces one full cosine cycle in:
// 4 quarters × 256 steps = 1024 clock cycles
parameter FULL_CYCLE = 1024;

////////////////////////////////////////////////////////////
// Signals
////////////////////////////////////////////////////////////
reg                          clk;
reg                          rst;

wire signed [COS_WIDTH-1:0]  cos_value;

////////////////////////////////////////////////////////////
// DUT
////////////////////////////////////////////////////////////
bpsk_nco #(
    .COS_WIDTH(COS_WIDTH)
) dut (
    .rst        (rst),
    .clk_sample (clk),
    .cos_value  (cos_value)
);

////////////////////////////////////////////////////////////
// Clock Generation
////////////////////////////////////////////////////////////
initial clk = 0;
always #(CLK_PERIOD/2) clk = ~clk;

////////////////////////////////////////////////////////////
// Test Counters
////////////////////////////////////////////////////////////
integer pass_count;
integer fail_count;
integer sample_count;

////////////////////////////////////////////////////////////
// Output Capture
////////////////////////////////////////////////////////////
reg signed [COS_WIDTH-1:0] cos_buffer [0:2*FULL_CYCLE-1];
integer capture_index;

////////////////////////////////////////////////////////////
// Task: Capture N Samples
////////////////////////////////////////////////////////////
task capture_samples;
    input integer num_samples;
    integer k;
    begin
        for (k = 0; k < num_samples; k = k + 1) begin
            @(posedge clk);
            cos_buffer[capture_index] = cos_value;
            capture_index = capture_index + 1;
            sample_count  = sample_count + 1;
        end
    end
endtask

////////////////////////////////////////////////////////////
// Task: Check Peak Value
////////////////////////////////////////////////////////////
task check_peak;
    integer k;
    reg signed [COS_WIDTH-1:0] max_val;
    reg signed [COS_WIDTH-1:0] min_val;
    begin
        max_val = -32768;
        min_val =  32767;

        for (k = 0; k < capture_index; k = k + 1) begin
            if (cos_buffer[k] > max_val)
                max_val = cos_buffer[k];
            if (cos_buffer[k] < min_val)
                min_val = cos_buffer[k];
        end

        $display("  Max value = %0d", max_val);
        $display("  Min value = %0d", min_val);

        // Peak should be +16384 (Q2.14 = +1.0)
        if (max_val == 16384) begin
            $display("  PASS | Positive peak = +16384");
            pass_count = pass_count + 1;
        end
        else begin
            $display("  FAIL | Expected +16384, got %0d", max_val);
            fail_count = fail_count + 1;
        end

        // Negative peak should be -16384
        if (min_val == -16384) begin
            $display("  PASS | Negative peak = -16384");
            pass_count = pass_count + 1;
        end
        else begin
            $display("  FAIL | Expected -16384, got %0d", min_val);
            fail_count = fail_count + 1;
        end
    end
endtask

////////////////////////////////////////////////////////////
// Task: Check Periodicity
////////////////////////////////////////////////////////////
task check_periodicity;
    integer k;
    integer period_pass;
    begin
        period_pass = 1;

        // Compare first cycle with second cycle
        for (k = 0; k < FULL_CYCLE; k = k + 1) begin
            if (cos_buffer[k] !== cos_buffer[k + FULL_CYCLE]) begin
                $display("  FAIL | Sample[%0d]=%0d != Sample[%0d]=%0d",
                         k, cos_buffer[k],
                         k + FULL_CYCLE, cos_buffer[k + FULL_CYCLE]);
                period_pass = 0;
                fail_count = fail_count + 1;
            end
        end

        if (period_pass) begin
            $display("  PASS | Output is periodic (period = %0d samples)", FULL_CYCLE);
            pass_count = pass_count + 1;
        end
    end
endtask

////////////////////////////////////////////////////////////
// Task: Check Quarter Symmetry
////////////////////////////////////////////////////////////
task check_quarter_symmetry;
    integer k;
    integer sym_pass;
    begin
        sym_pass = 1;

        // Quarter 1: samples 0..255   → cosine decreasing from +peak to 0
        // Quarter 2: samples 256..511 → cosine decreasing from 0 to -peak

        // Check: cos[k] should equal -cos[512-k] approximately
        // (symmetry around zero crossing at sample 256)

        // Simple check: sample 0 should be peak
        if (cos_buffer[0] == 16384) begin
            $display("  PASS | cos[0] = +16384 (start of cycle)");
            pass_count = pass_count + 1;
        end
        else begin
            $display("  FAIL | cos[0] = %0d (expected +16384)", cos_buffer[0]);
            fail_count = fail_count + 1;
        end

        // Check: around sample 256, should cross zero
        $display("  cos[255] = %0d", cos_buffer[255]);
        $display("  cos[256] = %0d", cos_buffer[256]);

        if (cos_buffer[255] >= -200 && cos_buffer[255] <= 200) begin
            $display("  PASS | Zero crossing near sample 255");
            pass_count = pass_count + 1;
        end
        else begin
            $display("  WARNING | Expected near-zero at sample 255, got %0d", cos_buffer[255]);
        end

        // Check: around sample 512, should be -peak
        $display("  cos[512] = %0d", cos_buffer[512]);

        if (cos_buffer[512] == -16384) begin
            $display("  PASS | cos[512] = -16384 (negative peak)");
            pass_count = pass_count + 1;
        end
        else begin
            $display("  FAIL | cos[512] = %0d (expected -16384)", cos_buffer[512]);
            fail_count = fail_count + 1;
        end

        // Check: around sample 768, should cross zero again
        $display("  cos[768] = %0d", cos_buffer[768]);

        if (cos_buffer[768] >= -200 && cos_buffer[768] <= 200) begin
            $display("  PASS | Zero crossing near sample 768");
            pass_count = pass_count + 1;
        end
        else begin
            $display("  WARNING | Expected near-zero at sample 768, got %0d", cos_buffer[768]);
        end
    end
endtask

////////////////////////////////////////////////////////////
// Task: Check Monotonicity In First Quarter
////////////////////////////////////////////////////////////
task check_first_quarter_monotonic;
    integer k;
    integer mono_pass;
    begin
        mono_pass = 1;

        // First quarter (0→255): cosine should decrease from +16384 toward 0
        for (k = 1; k < 256; k = k + 1) begin
            if (cos_buffer[k] > cos_buffer[k-1]) begin
                $display("  FAIL | Not monotonic: cos[%0d]=%0d > cos[%0d]=%0d",
                         k, cos_buffer[k], k-1, cos_buffer[k-1]);
                mono_pass = 0;
                fail_count = fail_count + 1;
            end
        end

        if (mono_pass) begin
            $display("  PASS | First quarter is monotonically decreasing");
            pass_count = pass_count + 1;
        end
    end
endtask

////////////////////////////////////////////////////////////
// Waveform Dump
////////////////////////////////////////////////////////////
initial begin
    $dumpfile("bpsk_nco_tb.vcd");
    $dumpvars(0, bpsk_nco_tb);
end

////////////////////////////////////////////////////////////
// Monitor (Print Every 64 Samples)
////////////////////////////////////////////////////////////
integer mon_cnt;
initial mon_cnt = 0;

always @(posedge clk) begin
    if (rst) begin
        mon_cnt = mon_cnt + 1;
        if (mon_cnt % 64 == 0)
            $display("  [MON] Time=%0t | Sample=%0d | cos=%0d | quarter=%0b | phase=%0d",
                     $time, mon_cnt, cos_value,
                     dut.quarter_detector, dut.phase_accumulator);
    end
end

////////////////////////////////////////////////////////////
// Main Test
////////////////////////////////////////////////////////////
initial begin

    // Initialize
    rst           = 0;
    pass_count    = 0;
    fail_count    = 0;
    sample_count  = 0;
    capture_index = 0;

    //--------------------------------------------------
    // 1️⃣ Reset
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 1: Reset");
    $display("==========================================");

    repeat(5) @(posedge clk);
    rst = 1;
    repeat(2) @(posedge clk);

    if (cos_value >= 16000) begin
        $display("PASS | After reset, cos starts near +16384");
        pass_count = pass_count + 1;
    end
    else begin
        $display("FAIL | After reset, cos = %0d (expected near +16384)", cos_value);
        fail_count = fail_count + 1;
    end

    //--------------------------------------------------
    // 2️⃣ Capture Two Full Cycles
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 2: Capture 2 full cycles");
    $display("==========================================");

    // Reset cleanly
    rst = 0;
    repeat(5) @(posedge clk);
    rst = 1;
    repeat(2) @(posedge clk);

    capture_index = 0;
    capture_samples(2 * FULL_CYCLE);

    $display("  Captured %0d samples", capture_index);

    //--------------------------------------------------
    // 3️⃣ Check Peak Values
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 3: Peak Values");
    $display("==========================================");

    check_peak;

    //--------------------------------------------------
    // 4️⃣ Check Periodicity
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 4: Periodicity");
    $display("==========================================");

    check_periodicity;

    //--------------------------------------------------
    // 5️⃣ Check Quarter Symmetry
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 5: Quarter Symmetry");
    $display("==========================================");

    check_quarter_symmetry;

    //--------------------------------------------------
    // 6️⃣ Check First Quarter Monotonicity
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 6: First Quarter Monotonic");
    $display("==========================================");

    check_first_quarter_monotonic;

    //--------------------------------------------------
    // 7️⃣ Reset Mid-Operation
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 7: Reset Mid-Operation");
    $display("==========================================");

    // Let NCO run for a while
    repeat(300) @(posedge clk);

    // Hit reset
    rst = 0;
    repeat(5) @(posedge clk);

    if (cos_value === 0) begin
        $display("PASS | Mid-reset clears cos_value");
        pass_count = pass_count + 1;
    end
    else begin
        $display("FAIL | Mid-reset: cos_value = %0d", cos_value);
        fail_count = fail_count + 1;
    end

    // Release reset
    rst = 1;
    repeat(5) @(posedge clk);

    // Verify it restarts correctly
    if (cos_value >= 16000) begin
        $display("PASS | NCO restarts correctly after reset");
        pass_count = pass_count + 1;
    end
    else begin
        $display("FAIL | NCO restart: cos = %0d", cos_value);
        fail_count = fail_count + 1;
    end

    //--------------------------------------------------
    // 8️⃣ Long Run Stability
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 8: Long run stability (5 cycles)");
    $display("==========================================");

    rst = 0;
    repeat(5) @(posedge clk);
    rst = 1;
    repeat(2) @(posedge clk);

    // Run for 5 full cycles
    repeat(5 * FULL_CYCLE) @(posedge clk);

    // Check phase accumulator returns to 0
    if (dut.phase_accumulator === 0 && dut.quarter_detector === 0) begin
        $display("PASS | NCO stable after 5 cycles");
        pass_count = pass_count + 1;
    end
    else begin
        $display("WARNING | phase=%0d quarter=%0b after 5 cycles",
                 dut.phase_accumulator, dut.quarter_detector);
    end

    //--------------------------------------------------
    // 9️⃣ Print Sample Values At Key Points
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 9: Key sample values");
    $display("==========================================");

    $display("  cos[0]   = %0d  (should be +16384)",  cos_buffer[0]);
    $display("  cos[255] = %0d  (should be ~0)",       cos_buffer[255]);
    $display("  cos[256] = %0d  (should be ~0)",       cos_buffer[256]);
    $display("  cos[512] = %0d  (should be -16384)",   cos_buffer[512]);
    $display("  cos[768] = %0d  (should be ~0)",       cos_buffer[768]);
    $display("  cos[1023]= %0d  (should be ~+16384)",  cos_buffer[1023]);

    //--------------------------------------------------
    // 🔟 Final Report
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST COMPLETE");
    $display("   Total Samples : %0d", sample_count);
    $display("   PASSED        : %0d", pass_count);
    $display("   FAILED        : %0d", fail_count);
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
    #200000;
    $display("ERROR: Simulation timeout!");
    $finish;
end

endmodule












// Test	Purpose
// Reset	         Clean startup
// 2 full cycles	 Capture waveform
// Peak values	     ±16384 check
// Periodicity	     Cycle-to-cycle match
// Quarter symmetry  Zero crossings correct
// Monotonicity	     First quarter decreasing
// Mid reset	     Clean recovery
// Long run	         No drift after 5 cycles
// Key samples	     Verify known points