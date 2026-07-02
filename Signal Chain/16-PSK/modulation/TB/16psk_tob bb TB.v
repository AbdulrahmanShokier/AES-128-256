`timescale 1ns / 1ps

module psk16_tx_top_bb_tb;

////////////////////////////////////////////////////////////
// Parameters
////////////////////////////////////////////////////////////
parameter DATA_WIDTH  = 16;
parameter FRAC_WIDTH  = 14;
parameter COEFF_WIDTH = 16;
parameter NUM_TAPS    = 33;
parameter UPSAMPLE    = 4;
parameter CLK_PERIOD  = 10;

parameter PIPELINE_FLUSH = 70;

////////////////////////////////////////////////////////////
// Signals
////////////////////////////////////////////////////////////
reg                          clk_sample;
reg                          rst;
reg                          valid_in;
reg  [3:0]                   data_in;

wire signed [DATA_WIDTH-1:0] I_out;
wire signed [DATA_WIDTH-1:0] Q_out;

////////////////////////////////////////////////////////////
// File Handle — Single file for both I and Q
////////////////////////////////////////////////////////////
integer file_IQ;
integer sample_idx;

////////////////////////////////////////////////////////////
// DUT
////////////////////////////////////////////////////////////
top_16psk_baseband #(
    .DATA_WIDTH    (DATA_WIDTH),
    .FRAC_WIDTH    (FRAC_WIDTH),
    .COEFF_WIDTH   (COEFF_WIDTH),
    .NUM_TAPS      (NUM_TAPS),
    .UPS_FACTOR    (UPSAMPLE)
) dut (
    .clk_sample (clk_sample),
    .rst        (rst),
    .valid_in   (valid_in),
    .data_in    (data_in),
    .I_out      (I_out),
    .Q_out      (Q_out)
);

////////////////////////////////////////////////////////////
// Clock Generation — single clock
////////////////////////////////////////////////////////////
initial clk_sample = 0;
always #(CLK_PERIOD/2) clk_sample = ~clk_sample;

////////////////////////////////////////////////////////////
// Counters
////////////////////////////////////////////////////////////
integer pass_count;
integer fail_count;
integer symbols_sent_count;

////////////////////////////////////////////////////////////
// Capture Buffer
////////////////////////////////////////////////////////////
reg signed [DATA_WIDTH-1:0] I_capture [0:4095];
reg signed [DATA_WIDTH-1:0] Q_capture [0:4095];
integer                     capture_idx;
integer                     capture_en;

////////////////////////////////////////////////////////////
// Data Logger — Single CSV with I and Q columns
// Format: sample, I_out, Q_out, valid_in
////////////////////////////////////////////////////////////
always @(posedge clk_sample) begin
    if (rst) begin
        $fwrite(file_IQ, "%0d,%0d,%0d,%0b\n",
                sample_idx,
                $signed(I_out),
                $signed(Q_out),
                valid_in);
        sample_idx = sample_idx + 1;
    end
end

////////////////////////////////////////////////////////////
// Capture Buffer — I and Q
////////////////////////////////////////////////////////////
always @(posedge clk_sample) begin
    if (rst) begin
        if (capture_en && capture_idx < 4096) begin
            I_capture[capture_idx] = I_out;
            Q_capture[capture_idx] = Q_out;
            capture_idx = capture_idx + 1;
        end
    end
end

////////////////////////////////////////////////////////////
// Task: Send One 4-bit Symbol
////////////////////////////////////////////////////////////
task send_symbol;
    input [3:0] sym;
    begin
        @(posedge clk_sample);
        #1;

        while (dut.symbol_cnt !== 0) begin
            @(posedge clk_sample);
            #1;
        end

        data_in  = sym;
        valid_in = 1'b1;

        @(posedge clk_sample);
        #1;

        valid_in = 1'b0;
        data_in  = 4'b0000;

        symbols_sent_count = symbols_sent_count + 1;
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
            if (I_out !== 0) nonzero_found = 1;
            if (Q_out !== 0) nonzero_found = 1;
        end

        if (!nonzero_found) begin
            $display("  PASS | I_out and Q_out are zero during reset");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL | Output not zero during reset: I_out=%0d Q_out=%0d",
                     I_out, Q_out);
            fail_count = fail_count + 1;
        end
    end
endtask

////////////////////////////////////////////////////////////
// Task: Check Output Is Non-Zero After Pipeline Flush
////////////////////////////////////////////////////////////
task check_valid_output;
    input integer wait_cycles;
    integer k;
    integer nonzero_found;
    begin
        nonzero_found = 0;
        for (k = 0; k < wait_cycles; k = k + 1) begin
            @(posedge clk_sample);
            #1;
            if (I_out !== 0 || Q_out !== 0)
                nonzero_found = 1;
        end

        if (nonzero_found) begin
            $display("  PASS | I_out/Q_out went non-zero within %0d cycles", wait_cycles);
            $display("         I_out = %0d | Q_out = %0d", I_out, Q_out);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL | I_out/Q_out stayed zero for %0d cycles", wait_cycles);
            fail_count = fail_count + 1;
        end
    end
endtask

////////////////////////////////////////////////////////////
// Main Test Sequence
////////////////////////////////////////////////////////////
initial begin

    // Initialize
    rst                = 0;
    valid_in           = 0;
    data_in            = 4'b0000;
    pass_count         = 0;
    fail_count         = 0;
    symbols_sent_count = 0;
    capture_idx        = 0;
    capture_en         = 0;
    sample_idx         = 0;

    // Open single CSV file
    file_IQ = $fopen("psk16_IQ_data.csv", "w");

    if (!file_IQ) begin
        $display("ERROR: Could not open psk16_IQ_data.csv");
        $finish;
    end

    // Write CSV header
    $fwrite(file_IQ, "sample,I_out,Q_out,valid_in\n");

    //══════════════════════════════════════════════════
    // TEST 1: Reset Verification
    //══════════════════════════════════════════════════
    $display("==========================================");
    $display("   TEST 1: Reset Verification");
    $display("==========================================");

    rst = 0;
    check_reset_output;

    repeat(5) @(posedge clk_sample);
    #1;
    rst = 1;              // files already open ✅
    repeat(5) @(posedge clk_sample);
    #1;
    $display("  PASS | Reset released, DUT running");

    //══════════════════════════════════════════════════
    // TEST 2: Output Activates After Symbol Sent
    //══════════════════════════════════════════════════
    $display("==========================================");
    $display("   TEST 2: Output After Symbol Sent");
    $display("==========================================");

    capture_en  = 1;
    capture_idx = 0;

    send_symbol(4'b0000);
    send_symbol(4'b0000);
    send_symbol(4'b0000);
    send_symbol(4'b0000);
    send_symbol(4'b1010);   // 
    send_symbol(4'b0101);   // 
    send_symbol(4'b0101);   // 
    send_symbol(4'b1100);   // 

    check_valid_output(PIPELINE_FLUSH);

    // Flush remaining pipeline
    $display("  Flushing pipeline...");
    flush_pipeline(PIPELINE_FLUSH);
    valid_in = 1'b0;

    // Dump captured samples to console
    $display("  Captured %0d samples:", capture_idx);
    begin : dump_block
        integer i;
        for (i = 0; i < capture_idx && i < 64; i = i + 1) begin
            $display("    [%0d] I=%0d | Q=%0d",
                     i, I_capture[i], Q_capture[i]);
        end
    end

    capture_en = 0;

    //══════════════════════════════════════════════════
    // Summary
    //══════════════════════════════════════════════════
    $display("==========================================");
    $display("   SUMMARY");
    $display("==========================================");
    $display("   Symbols Sent : %0d", symbols_sent_count);
    $display("   PASS         : %0d", pass_count);
    $display("   FAIL         : %0d", fail_count);
    $display("==========================================");
    $display("   File written:");
    $display("     psk16_IQ_data.csv  (sample, I_out, Q_out, valid_in)");
    $display("==========================================");

    // Close file
    $fclose(file_IQ);

    #100;
    $finish;
end

endmodule