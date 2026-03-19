`timescale 1ns / 1ps

module bpsk_upsampler_tb;

////////////////////////////////////////////////////////////
// Parameters
////////////////////////////////////////////////////////////
parameter DATA_WIDTH      = 16;
parameter Counter_WIDTH   = 2;
parameter upsample_factor = 4;
parameter CLK_PERIOD      = 10;  // 100 MHz
parameter FRAC_WIDTH      = 14;

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
bpsk_upsampler #(
    .DATA_WIDTH     (DATA_WIDTH),
    .Counter_WIDTH  (Counter_WIDTH),
    .upsample_factor(upsample_factor)
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
// Expected Values
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
// Task: Send One Symbol (Aligned to counter == 0)
////////////////////////////////////////////////////////////
task send_symbol;
    input signed [DATA_WIDTH-1:0] symbol;
    begin
        // Wait until counter == 0
        @(posedge clk);
        while (dut.counter !== 0)
            @(posedge clk);

        data_in  <= symbol;
        valid_in <= 1'b1;
        @(posedge clk);
        valid_in <= 1'b0;
        data_in  <= 0;
    end
endtask

////////////////////////////////////////////////////////////
// Task: Check 4 Output Samples (symbol, 0, 0, 0)
////////////////////////////////////////////////////////////
task check_upsampled;
    input signed [DATA_WIDTH-1:0] expected_symbol;
    integer i;
    begin
        for (i = 0; i < upsample_factor; i = i + 1) begin
            @(posedge clk);
            if (valid_out) begin
                if (i == 0) begin
                    // First sample should be symbol value
                    if (data_out === expected_symbol) begin
                        $display("PASS | Time=%0t | Sample[%0d] = %0d (expected %0d)",
                                 $time, i, data_out, expected_symbol);
                        pass_count = pass_count + 1;
                    end
                    else begin
                        $display("FAIL | Time=%0t | Sample[%0d] = %0d (expected %0d)",
                                 $time, i, data_out, expected_symbol);
                        fail_count = fail_count + 1;
                    end
                end
                else begin
                    // Remaining samples should be zero
                    if (data_out === ZERO) begin
                        $display("PASS | Time=%0t | Sample[%0d] = %0d (expected 0)",
                                 $time, i, data_out);
                        pass_count = pass_count + 1;
                    end
                    else begin
                        $display("FAIL | Time=%0t | Sample[%0d] = %0d (expected 0)",
                                 $time, i, data_out);
                        fail_count = fail_count + 1;
                    end
                end
                sample_count = sample_count + 1;
            end
        end
    end
endtask



////////////////////////////////////////////////////////////
// Monitor
////////////////////////////////////////////////////////////
always @(posedge clk) begin
    if (valid_out)
        $display("  [MONITOR] Time=%0t | data_out=%0d | valid_out=%0b | counter=%0d",
                 $time, data_out, valid_out, dut.counter);
end

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

    //--------------------------------------------------
    // 1️⃣ Reset
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 1: Reset");
    $display("==========================================");

    repeat(5) @(posedge clk);
    rst = 1;
    repeat(5) @(posedge clk);

    // Check output is zero after reset
    if (data_out === ZERO && valid_out === 1'b0) begin
        $display("PASS | Reset → output zero, valid low");
        pass_count = pass_count + 1;
    end
    else begin
        $display("FAIL | Reset state incorrect");
        fail_count = fail_count + 1;
    end

    //--------------------------------------------------
    // 2️⃣ Single Symbol: +1
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 2: Single symbol +1 (16384)");
    $display("==========================================");

    send_symbol(POS_ONE);
    check_upsampled(POS_ONE);

    repeat(8) @(posedge clk);

    //--------------------------------------------------
    // 3️⃣ Single Symbol: -1
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 3: Single symbol -1 (-16384)");
    $display("==========================================");

    send_symbol(NEG_ONE);
    check_upsampled(NEG_ONE);

    repeat(8) @(posedge clk);

    //--------------------------------------------------
    // 4️⃣ Two Consecutive Symbols: +1, -1
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 4: Consecutive +1, -1");
    $display("==========================================");

    send_symbol(POS_ONE);
    check_upsampled(POS_ONE);

    send_symbol(NEG_ONE);
    check_upsampled(NEG_ONE);

    repeat(8) @(posedge clk);

    //--------------------------------------------------
    // 5️⃣ Alternating Symbols
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 5: Alternating +1/-1 x4");
    $display("==========================================");

    send_symbol(POS_ONE);
    check_upsampled(POS_ONE);

    send_symbol(NEG_ONE);
    check_upsampled(NEG_ONE);

    send_symbol(POS_ONE);
    check_upsampled(POS_ONE);

    send_symbol(NEG_ONE);
    check_upsampled(NEG_ONE);

    repeat(8) @(posedge clk);

    //--------------------------------------------------
    // 6️⃣ All +1 Symbols
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 6: All +1 x4");
    $display("==========================================");

    repeat(4) begin
        send_symbol(POS_ONE);
        check_upsampled(POS_ONE);
    end

    repeat(8) @(posedge clk);

    //--------------------------------------------------
    // 7️⃣ All -1 Symbols
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 7: All -1 x4");
    $display("==========================================");

    repeat(4) begin
        send_symbol(NEG_ONE);
        check_upsampled(NEG_ONE);
    end

    repeat(8) @(posedge clk);

    //--------------------------------------------------
    // 8️⃣ No valid_in for multiple cycles
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 8: No valid → no output");
    $display("==========================================");

    valid_in <= 1'b0;
    repeat(16) @(posedge clk);

    if (valid_out === 1'b0) begin
        $display("PASS | No valid_in → valid_out stays low");
        pass_count = pass_count + 1;
    end
    else begin
        $display("FAIL | valid_out should be low");
        fail_count = fail_count + 1;
    end

    //--------------------------------------------------
    // 9️⃣ Reset Mid-Operation
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 9: Reset mid-operation");
    $display("==========================================");

    send_symbol(POS_ONE);
    @(posedge clk);

    // Hit reset
    rst = 0;
    repeat(3) @(posedge clk);

    if (data_out === ZERO && valid_out === 1'b0) begin
        $display("PASS | Mid-reset clears output");
        pass_count = pass_count + 1;
    end
    else begin
        $display("FAIL | Mid-reset did not clear");
        fail_count = fail_count + 1;
    end

    // Release reset
    rst = 1;
    repeat(5) @(posedge clk);

    // Resume normal operation
    send_symbol(NEG_ONE);
    check_upsampled(NEG_ONE);

    repeat(8) @(posedge clk);

    //--------------------------------------------------
    // 🔟 Arbitrary Value Test
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 10: Arbitrary value (8192)");
    $display("==========================================");

    send_symbol(16'sd8192);
    check_upsampled(16'sd8192);

    repeat(8) @(posedge clk);

    //--------------------------------------------------
    // Final Report
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
    #100000;
    $display("ERROR: Simulation timeout!");
    $finish;
end

endmodule