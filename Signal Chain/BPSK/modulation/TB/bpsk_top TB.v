`timescale 1ns / 1ps

module bpsk_tx_top_tb;

////////////////////////////////////////////////////////////
// Parameters
////////////////////////////////////////////////////////////
parameter DATA_WIDTH  = 16;
parameter FRAC_WIDTH  = 14;
parameter COEFF_WIDTH = 16;
parameter NUM_TAPS    = 33;
parameter COS_WIDTH   = 16;
parameter UPSAMPLE    = 4;

parameter CLK_PERIOD  = 10;  // 100 MHz sample clock

////////////////////////////////////////////////////////////
// Signals
////////////////////////////////////////////////////////////
reg                         clk_sample;
reg                         rst;
reg                         bit_valid;
reg                         bit_in;

wire signed [DATA_WIDTH-1:0] tx_out;
wire                         tx_valid;

////////////////////////////////////////////////////////////
// DUT Instantiation
////////////////////////////////////////////////////////////
bpsk_tx_top #(
    .DATA_WIDTH (DATA_WIDTH),
    .FRAC_WIDTH (FRAC_WIDTH),
    .COEFF_WIDTH(COEFF_WIDTH),
    .NUM_TAPS   (NUM_TAPS),
    .COS_WIDTH  (COS_WIDTH),
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
// Test Data
////////////////////////////////////////////////////////////
reg [15:0] test_bits;
integer    bit_index;

////////////////////////////////////////////////////////////
// Task: Send One Bit (Waits For Symbol Tick)
////////////////////////////////////////////////////////////
task send_bit;
    input bit_val;
    begin
        // Wait until symbol_tick (counter == 0)
        @(posedge clk_sample);
        while (dut.symbol_tick !== 1'b1)
            @(posedge clk_sample);

        bit_in    <= bit_val;
        bit_valid <= 1'b1;
        @(posedge clk_sample);
        bit_valid <= 1'b0;
        bit_in    <= 1'b0;
    end
endtask

////////////////////////////////////////////////////////////
// Monitor: Log Output When Valid
////////////////////////////////////////////////////////////
always @(posedge clk_sample) begin
    if (tx_valid) begin
        $display("Time=%0t | tx_out = %0d", $time, tx_out);
    end
end

////////////////////////////////////////////////////////////
// Optional: Dump Waveforms
////////////////////////////////////////////////////////////
initial begin
    $dumpfile("bpsk_tx_top_tb.vcd");
    $dumpvars(0, bpsk_tx_top_tb);
end

////////////////////////////////////////////////////////////
// Main Test Sequence
////////////////////////////////////////////////////////////
initial begin

    //--------------------------------------------------
    //  Initialize
    //--------------------------------------------------
    rst       = 0;
    bit_valid = 0;
    bit_in    = 0;

    //--------------------------------------------------
    //  Apply Reset
    //--------------------------------------------------
    repeat(10) @(posedge clk_sample);
    rst = 1;
    repeat(10) @(posedge clk_sample);

    $display("==========================================");
    $display("   BPSK TX Testbench Started");
    $display("==========================================");

    //--------------------------------------------------
    //  Send Known Bit Pattern
    //--------------------------------------------------
    test_bits = 16'b1010_1100_0111_0010;

    for (bit_index = 15; bit_index >= 0; bit_index = bit_index - 1) begin
        send_bit(test_bits[bit_index]);
        $display("Time=%0t | Sent bit[%0d] = %0b", $time, bit_index, test_bits[bit_index]);
    end

    //--------------------------------------------------
    //  Wait For Pipeline To Flush
    //--------------------------------------------------
    $display("==========================================");
    $display("   Waiting for pipeline flush...");
    $display("==========================================");

    repeat(200) @(posedge clk_sample);

    //--------------------------------------------------
    //  Send All Ones
    //--------------------------------------------------
    $display("==========================================");
    $display("   Sending all 1s...");
    $display("==========================================");

    repeat(8) send_bit(1'b1);

    repeat(100) @(posedge clk_sample);

    //--------------------------------------------------
    //  Send All Zeros
    //--------------------------------------------------
    $display("==========================================");
    $display("   Sending all 0s...");
    $display("==========================================");

    repeat(8) send_bit(1'b0);

    repeat(100) @(posedge clk_sample);

    //--------------------------------------------------
    //  Send Alternating Pattern
    //--------------------------------------------------
    $display("==========================================");
    $display("   Sending alternating 1010...");
    $display("==========================================");

    repeat(16) begin
        send_bit(1'b1);
        send_bit(1'b0);
    end

    repeat(200) @(posedge clk_sample);

    //--------------------------------------------------
    //  Test Reset Mid-Operation
    //--------------------------------------------------
    $display("==========================================");
    $display("   Testing mid-operation reset...");
    $display("==========================================");

    send_bit(1'b1);
    send_bit(1'b0);

    rst = 0;
    repeat(5) @(posedge clk_sample);
    rst = 1;
    repeat(10) @(posedge clk_sample);

    send_bit(1'b1);
    send_bit(1'b1);

    repeat(200) @(posedge clk_sample);

    //--------------------------------------------------
    //  End Simulation
    //--------------------------------------------------
    $display("==========================================");
    $display("   BPSK TX Testbench Complete");
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