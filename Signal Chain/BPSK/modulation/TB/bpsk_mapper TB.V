`timescale 1ns / 1ps

module bpsk_mapper_tb;

////////////////////////////////////////////////////////////
// Parameters
////////////////////////////////////////////////////////////
parameter DATA_WIDTH = 16;
parameter FRAC_WIDTH = 14;
parameter CLK_PERIOD = 10;  // 100 MHz

////////////////////////////////////////////////////////////
// Signals
////////////////////////////////////////////////////////////
reg                          clk;
reg                          rst;
reg                          valid_in;
reg                          data_in;

wire signed [DATA_WIDTH-1:0] data_out;
wire                         valid_out;

////////////////////////////////////////////////////////////
// DUT
////////////////////////////////////////////////////////////
bpsk_mapper #(
    .DATA_WIDTH(DATA_WIDTH),
    .FRAC_WIDTH(FRAC_WIDTH)
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

////////////////////////////////////////////////////////////
// Task: Send One Bit
////////////////////////////////////////////////////////////
task send_bit;
    input bit_val;
    begin
        @(posedge clk);
        data_in   <= bit_val;
        valid_in  <= 1'b1;
        @(posedge clk);
        valid_in  <= 1'b0;
        data_in   <= 1'b0;
    end
endtask

////////////////////////////////////////////////////////////
// Task: Check Output
////////////////////////////////////////////////////////////
integer pass_count;
integer fail_count;

task check_output;
    input signed [DATA_WIDTH-1:0] expected;
    begin
        @(posedge clk);  // wait for registered output
        if (data_out === expected && valid_out === 1'b1) begin
            $display("PASS | Time=%0t | data_out=%0d | expected=%0d",
                     $time, data_out, expected);
            pass_count = pass_count + 1;
        end
        else begin
            $display("FAIL | Time=%0t | data_out=%0d | expected=%0d | valid_out=%0b",
                     $time, data_out, expected, valid_out);
            fail_count = fail_count + 1;
        end
    end
endtask

////////////////////////////////////////////////////////////
// Waveform Dump
////////////////////////////////////////////////////////////
initial begin
    $dumpfile("bpsk_mapper_tb.vcd");
    $dumpvars(0, bpsk_mapper_tb);
end

////////////////////////////////////////////////////////////
// Main Test
////////////////////////////////////////////////////////////
initial begin

    // Initialize
    rst        = 0;
    valid_in   = 0;
    data_in    = 0;
    pass_count = 0;
    fail_count = 0;

    //--------------------------------------------------
    // 1️⃣ Reset
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 1: Reset");
    $display("==========================================");

    repeat(5) @(posedge clk);
    rst = 1;
    repeat(5) @(posedge clk);

    //--------------------------------------------------
    // 2️⃣ Send bit = 0 → expect +1 (+16384)
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 2: Bit 0 → +1");
    $display("==========================================");

    send_bit(1'b0);
    check_output(POS_ONE);

    //--------------------------------------------------
    // 3️⃣ Send bit = 1 → expect -1 (-16384)
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 3: Bit 1 → -1");
    $display("==========================================");

    send_bit(1'b1);
    check_output(NEG_ONE);

    //--------------------------------------------------
    // 4️⃣ Alternating bits
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 4: Alternating 1010");
    $display("==========================================");

    send_bit(1'b1);
    check_output(NEG_ONE);

    send_bit(1'b0);
    check_output(POS_ONE);

    send_bit(1'b1);
    check_output(NEG_ONE);

    send_bit(1'b0);
    check_output(POS_ONE);

    //--------------------------------------------------
    // 5️⃣ All ones
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 5: All 1s");
    $display("==========================================");

    repeat(4) begin
        send_bit(1'b1);
        check_output(NEG_ONE);
    end

    //--------------------------------------------------
    // 6️⃣ All zeros
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 6: All 0s");
    $display("==========================================");

    repeat(4) begin
        send_bit(1'b0);
        check_output(POS_ONE);
    end

    //--------------------------------------------------
    // 7️⃣ No valid_in → output should be zero
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 7: No valid → zero output");
    $display("==========================================");

    @(posedge clk);
    valid_in <= 1'b0;
    data_in  <= 1'b1;
    @(posedge clk);
    @(posedge clk);

    if (data_out === 0 && valid_out === 1'b0) begin
        $display("PASS | No valid → output zeroed");
        pass_count = pass_count + 1;
    end
    else begin
        $display("FAIL | Expected zero output when invalid");
        fail_count = fail_count + 1;
    end

    //--------------------------------------------------
    // 8️⃣ Reset mid-operation
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 8: Reset mid-operation");
    $display("==========================================");

    send_bit(1'b1);

    // Assert reset
    rst = 0;
    repeat(3) @(posedge clk);

    if (data_out === 0 && valid_out === 1'b0) begin
        $display("PASS | Reset clears output");
        pass_count = pass_count + 1;
    end
    else begin
        $display("FAIL | Reset did not clear output");
        fail_count = fail_count + 1;
    end

    // Release reset
    rst = 1;
    repeat(3) @(posedge clk);

    // Verify normal operation resumes
    send_bit(1'b0);
    check_output(POS_ONE);

    //--------------------------------------------------
    // 9️⃣ Bit stream test
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST 9: Bit stream 11001010");
    $display("==========================================");

    send_bit(1'b1); check_output(NEG_ONE);
    send_bit(1'b1); check_output(NEG_ONE);
    send_bit(1'b0); check_output(POS_ONE);
    send_bit(1'b0); check_output(POS_ONE);
    send_bit(1'b1); check_output(NEG_ONE);
    send_bit(1'b0); check_output(POS_ONE);
    send_bit(1'b1); check_output(NEG_ONE);
    send_bit(1'b0); check_output(POS_ONE);

    //--------------------------------------------------
    // 🔟 Final Report
    //--------------------------------------------------
    $display("==========================================");
    $display("   TEST COMPLETE");
    $display("   PASSED: %0d", pass_count);
    $display("   FAILED: %0d", fail_count);
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
    #50000;
    $display("ERROR: Simulation timeout!");
    $finish;
end

endmodule