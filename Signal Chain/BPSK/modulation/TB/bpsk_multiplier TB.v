`timescale 1ns / 1ps

module bpsk_multiplier_tb;

////////////////////////////////////////////////////////////
// Parameters
////////////////////////////////////////////////////////////
parameter DATA_WIDTH = 16;
parameter FRACTION   = 14;
parameter CLK_PERIOD = 10;

////////////////////////////////////////////////////////////
// Signals
////////////////////////////////////////////////////////////
reg                          clk;
reg                          rst;
reg                          valid_in;
reg  signed [DATA_WIDTH-1:0] fir_data_in;
reg  signed [DATA_WIDTH-1:0] nco_cos_in;

wire signed [DATA_WIDTH-1:0] signal_modulated;
wire                         valid_out;

////////////////////////////////////////////////////////////
// DUT
////////////////////////////////////////////////////////////
bpsk_multiplier #(
    .DATA_WIDTH(DATA_WIDTH),
    .FRACTION  (FRACTION)
) dut (
    .rst              (rst),
    .clk_sample       (clk),
    .valid_in         (valid_in),
    .fir_data_in      (fir_data_in),
    .nco_cos_in       (nco_cos_in),
    .signal_modulated (signal_modulated),
    .valid_out        (valid_out)
);

////////////////////////////////////////////////////////////
// Clock Generation
////////////////////////////////////////////////////////////
initial clk = 0;
always #(CLK_PERIOD/2) clk = ~clk;

////////////////////////////////////////////////////////////
// Constants (Q2.14)
////////////////////////////////////////////////////////////
localparam signed [DATA_WIDTH-1:0] POS_ONE    =  16384;   // +1.0
localparam signed [DATA_WIDTH-1:0] NEG_ONE    = -16384;   // -1.0
localparam signed [DATA_WIDTH-1:0] POS_HALF   =  8192;    // +0.5
localparam signed [DATA_WIDTH-1:0] NEG_HALF   = -8192;    // -0.5
localparam signed [DATA_WIDTH-1:0] POS_QUARTER=  4096;    // +0.25
localparam signed [DATA_WIDTH-1:0] ZERO       =  0;

////////////////////////////////////////////////////////////
// Test Counters
////////////////////////////////////////////////////////////
integer pass_count;
integer fail_count;

////////////////////////////////////////////////////////////
// Task: Apply Inputs And Wait For Output
////////////////////////////////////////////////////////////
task apply_and_check;
    input signed [DATA_WIDTH-1:0] fir_val;
    input signed [DATA_WIDTH-1:0] nco_val;
    input signed [DATA_WIDTH-1:0] expected;
    input integer tolerance;
    reg   signed [DATA_WIDTH-1:0] actual;
    begin
        // Apply inputs
        @(posedge clk);
        fir_data_in <= fir_val;
        nco_cos_in  <= nco_val;
        valid_in    <= 1'b1;
        @(posedge clk);
        valid_in    <= 1'b0;

        // Wait 2 cycles (pipeline latency)
        @(posedge clk);
        @(posedge clk);

        actual = signal_modulated;

        if ((actual >= expected - tolerance) && 
            (actual <= expected + tolerance)) begin
            $display("PASS | fir=%0d × nco=%0d = %0d (expected %0d ±%0d)",
                     fir_val, nco_val, actual, expected, tolerance);
            pass_count = pass_count + 1;
        end
        else begin
            $display("FAIL | fir=%0d × nco=%0d = %0d (expected %0d ±%0d)",
                     fir_val, nco_val, actual, expected, tolerance);
            fail_count = fail_count + 1;
        end
    end
endtask

////////////////////////////////////////////////////////////
// Waveform Dump
////////////////////////////////////////////////////////////
initial begin
    $dumpfile("bpsk_multiplier_tb.vcd");
    $dumpvars(0, bpsk_multiplier_tb);
end

////////////////////////////////////////////////////////////
// Monitor
////////////////////////////////////////////////////////////
always @(posedge clk) begin
    if (valid_out)
        $display("  [MON] Time=%0t | output=%0d | valid=%0b",
                 $time, signal_modulated, valid_out);
end

////////////////////////////////////////////////////////////
// Main Test
////////////////////////////////////////////////////////////
initial begin

    // Initialize
    rst         = 0;
    valid_in    = 0;
    fir_data_in = 0;
    nco_cos_in  = 0;
    pass_count  = 0;
    fail_count  = 0;

    //--------------------------------------------------
    // 1️⃣ Reset
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 1: Reset");
    $display("==========================================");

    repeat(5) @(posedge clk);
    rst = 1;
    repeat(5) @(posedge clk);

    if (signal_modulated === 0 && valid_out === 1'b0) begin
        $display("PASS | Reset → output zero");
        pass_count = pass_count + 1;
    end
    else begin
        $display("FAIL | Reset state incorrect");
        fail_count = fail_count + 1;
    end

    //--------------------------------------------------
    // 2️⃣ +1.0 × +1.0 = +1.0
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 2: +1.0 × +1.0 = +1.0");
    $display("==========================================");

    // +1.0 × +1.0 = +1.0
    // 16384 × 16384 >> 14 = 16384
    apply_and_check(POS_ONE, POS_ONE, POS_ONE, 1);

    //--------------------------------------------------
    // 3️⃣ +1.0 × -1.0 = -1.0
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 3: +1.0 × -1.0 = -1.0");
    $display("==========================================");

    apply_and_check(POS_ONE, NEG_ONE, NEG_ONE, 1);

    //--------------------------------------------------
    // 4️⃣ -1.0 × -1.0 = +1.0
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 4: -1.0 × -1.0 = +1.0");
    $display("==========================================");

    apply_and_check(NEG_ONE, NEG_ONE, POS_ONE, 1);

    //--------------------------------------------------
    // 5️⃣ -1.0 × +1.0 = -1.0
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 5: -1.0 × +1.0 = -1.0");
    $display("==========================================");

    apply_and_check(NEG_ONE, POS_ONE, NEG_ONE, 1);

    //--------------------------------------------------
    // 6️⃣ +0.5 × +1.0 = +0.5
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 6: +0.5 × +1.0 = +0.5");
    $display("==========================================");

    // 8192 × 16384 >> 14 = 8192
    apply_and_check(POS_HALF, POS_ONE, POS_HALF, 1);

    //--------------------------------------------------
    // 7️⃣ +0.5 × -1.0 = -0.5
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 7: +0.5 × -1.0 = -0.5");
    $display("==========================================");

    apply_and_check(POS_HALF, NEG_ONE, NEG_HALF, 1);

    //--------------------------------------------------
    // 8️⃣ +0.5 × +0.5 = +0.25
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 8: +0.5 × +0.5 = +0.25");
    $display("==========================================");

    // 8192 × 8192 >> 14 = 4096
    apply_and_check(POS_HALF, POS_HALF, POS_QUARTER, 1);

    //--------------------------------------------------
    // 9️⃣ 0 × +1.0 = 0
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 9: 0 × +1.0 = 0");
    $display("==========================================");

    apply_and_check(ZERO, POS_ONE, ZERO, 0);

    //--------------------------------------------------
    // 🔟 0 × 0 = 0
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 10: 0 × 0 = 0");
    $display("==========================================");

    apply_and_check(ZERO, ZERO, ZERO, 0);

    //--------------------------------------------------
    // 1️⃣1️⃣ Arbitrary: 0.75 × 0.5
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 11: 0.75 × 0.5 = 0.375");
    $display("==========================================");

    // 0.75 = 12288, 0.5 = 8192
    // 12288 × 8192 >> 14 = 6144
    // 0.375 = 6144
    apply_and_check(16'sd12288, POS_HALF, 16'sd6144, 1);

    //--------------------------------------------------
    // 1️⃣2️⃣ Pipeline Latency Verification
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 12: Pipeline latency = 2 cycles");
    $display("==========================================");

    @(posedge clk);
    fir_data_in <= POS_ONE;
    nco_cos_in  <= POS_ONE;
    valid_in    <= 1'b1;

    @(posedge clk);  // Cycle 1: inputs registered
    valid_in <= 1'b0;

    if (valid_out === 1'b0) begin
        $display("  Cycle 1: valid_out = 0 (correct)");
    end

    @(posedge clk);  // Cycle 2: output registered

    if (valid_out === 1'b1) begin
        $display("  Cycle 2: valid_out = 1 (correct)");
        $display("PASS | Pipeline latency = 2 cycles");
        pass_count = pass_count + 1;
    end
    else begin
        $display("FAIL | Pipeline latency incorrect");
        fail_count = fail_count + 1;
    end

    //--------------------------------------------------
    // 1️⃣3️⃣ No valid_in → No output
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 13: No valid → no valid_out");
    $display("==========================================");

    valid_in    <= 1'b0;
    fir_data_in <= POS_ONE;
    nco_cos_in  <= POS_ONE;

    repeat(5) @(posedge clk);

    if (valid_out === 1'b0) begin
        $display("PASS | No valid_in → valid_out stays low");
        pass_count = pass_count + 1;
    end
    else begin
        $display("FAIL | valid_out should be low");
        fail_count = fail_count + 1;
    end

    //--------------------------------------------------
    // 1️⃣4️⃣ Reset Mid-Operation
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 14: Reset mid-operation");
    $display("==========================================");

    // Send data
    @(posedge clk);
    fir_data_in <= POS_ONE;
    nco_cos_in  <= NEG_ONE;
    valid_in    <= 1'b1;
    @(posedge clk);
    valid_in    <= 1'b0;

    // Hit reset
    rst = 0;
    repeat(3) @(posedge clk);

    if (signal_modulated === 0 && valid_out === 1'b0) begin
        $display("PASS | Mid-reset clears output");
        pass_count = pass_count + 1;
    end
    else begin
        $display("FAIL | Mid-reset did not clear");
        fail_count = fail_count + 1;
    end

    // Release reset
    rst = 1;
    repeat(3) @(posedge clk);

    // Resume normal
    apply_and_check(POS_HALF, POS_HALF, POS_QUARTER, 1);

    //--------------------------------------------------
    // 1️⃣5️⃣ Continuous Stream Test
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 15: Continuous stream");
    $display("==========================================");

    repeat(20) begin
        @(posedge clk);
        fir_data_in <= POS_ONE;
        nco_cos_in  <= POS_HALF;
        valid_in    <= 1'b1;
    end
    @(posedge clk);
    valid_in <= 1'b0;

    repeat(5) @(posedge clk);

    $display("  Continuous stream complete — check waveform");

    //--------------------------------------------------
    // Final Report
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST COMPLETE");
    $display("   PASSED : %0d", pass_count);
    $display("   FAILED : %0d", fail_count);
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
    #100000;
    $display("ERROR: Simulation timeout!");
    $finish;
end

endmodule


// What This Testbench Covers
// Test	                What It Verifies
// Reset	            Clean zero state
// +1 × +1	            Basic positive
// +1 × -1	            Sign flip
// -1 × -1	            Double negative
// -1 × +1	            Sign flip
// +0.5 × +1	        Scaling
// +0.5 × -1	        Scaling + sign
// +0.5 × +0.5	        Fractional multiply
// 0 × anything	        Zero handling
// 0.75 × 0.5	        Arbitrary values
// Pipeline latency	    Exactly 2 cycles
// No valid	            No spurious output
// Mid reset	        Clean recovery
// Continuous stream	Sustained operation