`timescale 1ns/1ps

module encoder_core_tb;

//========================= Parameters =============================
parameter m = 8;
parameter k = 223;
parameter n = 255;
parameter t = 16;

//========================= Signals ================================
reg              clk;
reg              rst;
reg  [m-1:0]     data_in;
reg              lfsr_clear;
reg              lfsr_enable;
reg              output_data_select;
reg              counter_clear;
reg              counter_enable;
wire [7:0]       counter;
wire [m-1:0]     data_out;

//========================= DUT ====================================
encoder_core #(
    .m(m),
    .k(k),
    .t(t)
) dut (
    .clk               (clk),
    .rst               (rst),
    .data_in           (data_in),
    .lfsr_clear        (lfsr_clear),
    .lfsr_enable       (lfsr_enable),
    .output_data_select(output_data_select),
    .counter_clear     (counter_clear),
    .counter_enable    (counter_enable),
    .counter           (counter),
    .data_out          (data_out)
);

//========================= Clock ==================================
initial clk = 0;
always #5 clk = ~clk;

//========================= Debug ==================================
integer dbg_i;

// Verify polynomial values
task verify_polynomial;
begin
    $display("\n=== Generator Polynomial Verification ===");
    $display("g[0]  = %3d (expected  45)", dut.g(0));
    $display("g[1]  = %3d (expected 216)", dut.g(1));
    $display("g[2]  = %3d (expected 239)", dut.g(2));
    $display("g[3]  = %3d (expected  24)", dut.g(3));
    $display("g[15] = %3d (expected 158)", dut.g(15));
    $display("g[31] = %3d (expected 232)", dut.g(31));
end
endtask

// Print LFSR state
task print_lfsr;
begin
    $display("\n=== LFSR State ===");
    for (dbg_i = 0; dbg_i < 32; dbg_i = dbg_i + 4)
        $display("%2d : %3d %3d %3d %3d", 
            dbg_i,
            dut.lfsr_regs[dbg_i],
            dut.lfsr_regs[dbg_i+1],
            dut.lfsr_regs[dbg_i+2],
            dut.lfsr_regs[dbg_i+3]);
end
endtask

// Monitor first few cycles
task monitor_cycle;
    input integer cycle_num;
begin
    $display("\n--- Cycle %0d ---", cycle_num);
    $display("data_in     = %3d", data_in);
    $display("lfsr[31]    = %3d", dut.lfsr_regs[31]);
    $display("feedback    = %3d", dut.feedback);
    $display("lfsr_enable = %b",  lfsr_enable);
end
endtask

//========================= Main Test ==============================
integer i;

initial begin
    // Initialize
    rst               = 0;
    data_in           = 0;
    lfsr_clear        = 1;
    lfsr_enable       = 0;
    output_data_select = 0;
    counter_clear     = 1;
    counter_enable    = 0;

    // Reset
    repeat(3) @(posedge clk); #1;
    rst = 1;
    repeat(2) @(posedge clk); #1;

    // Verify polynomial
    verify_polynomial;

    // Clear LFSR and counter
    lfsr_clear    = 1;
    counter_clear = 1;
    @(posedge clk); #1;
    lfsr_clear    = 0;
    counter_clear = 0;

    //--------------------------------------------------
    // Phase 1: Feed k=223 data bytes into LFSR
    //--------------------------------------------------
    $display("\n=== Phase 1: Feeding %0d data bytes ===", k);

    for (i = 0; i < k; i = i + 1) begin
        // Input: first byte = 1, rest = 0
        if (i == 0)
            data_in = 8'd1;
        else
            data_in = 8'd0;

        lfsr_enable    = 1;
        counter_enable = 1;

        // Monitor first 3 cycles
        if (i < 3) begin
            #1; // Wait for combinational to settle
            monitor_cycle(i);
        end

        @(posedge clk); #1;

        // Print LFSR after first 3 cycles
        if (i < 3) begin
            $display("After clock edge:");
            print_lfsr;
        end
    end

    // Disable LFSR
    lfsr_enable    = 0;
    counter_enable = 0;
    data_in        = 0;

    //--------------------------------------------------
    // Print final LFSR state
    //--------------------------------------------------
    $display("\n=== Final LFSR State (after %0d data bytes) ===", k);
    print_lfsr;

    //--------------------------------------------------
    // Phase 2: Output parity bytes
    //--------------------------------------------------
    $display("\n=== Phase 2: Reading %0d parity bytes ===", 2*t);

    output_data_select = 1;
    counter_enable     = 1;

    for (i = 0; i < 2*t; i = i + 1) begin
        @(posedge clk); #1;
        $display("Parity[%2d] = %3d", i, data_out);
    end

    //--------------------------------------------------
    // Compare with MATLAB expected parity
    //--------------------------------------------------
    $display("\n=== Expected MATLAB Parity ===");
    $display("139  27 233 163 227 203 114  27");
    $display("186  28  46  92   6 139 147 177");
    $display("  3 147  55 231 183 212 202 227");
    $display(" 97 156 244 225 222 116 141 243");

    //--------------------------------------------------
    // Done
    //--------------------------------------------------
    $display("\n=== Simulation Complete ===");
    repeat(5) @(posedge clk);
    $finish;
end

//========================= Waveform Dump ==========================
initial begin
    $dumpfile("encoder_core_tb.vcd");
    $dumpvars(0, encoder_core_tb);
end

//========================= Timeout ================================
initial begin
    #500000;
    $display("TIMEOUT!");
    $finish;
end

endmodule