`timescale 1ns/1ps

module encoder_fsm_tb;

//========================= Parameters ====================================
parameter m = 8;
parameter k = 223;
parameter n = 255;
parameter t = 16;

//========================= DUT Signals ====================================
reg         clk;
reg         rst;
reg         start_encode;
reg         data_valid;
reg  [7:0]  counter_tb;    // External counter to drive FSM input

wire [2:0]  current_state;
wire        lfsr_clear;
wire        lfsr_enable;
wire        output_data_select;
wire        data_out_valid;
wire        encoding_done;
wire        ready_for_data;
wire        counter_clear;
wire        counter_enable;

//========================= State Names for Display =======================
reg [127:0] state_name;
always @(*) begin
    case(current_state)
        3'b000: state_name = "IDLE        ";
        3'b011: state_name = "INIT        ";
        3'b001: state_name = "OUTPUT_DATA ";
        3'b010: state_name = "OUTPUT_PARITY";
        default: state_name = "UNKNOWN     ";
    endcase
end

//========================= DUT Instantiation =============================
encoder_fsm #(
    .k(k),
    .n(n),
    .t(t)
) dut (
    .clk               (clk),
    .rst               (rst),
    .start_encode      (start_encode),
    .data_valid        (data_valid),
    .counter           (counter_tb),
    .current_state     (current_state),
    .lfsr_clear        (lfsr_clear),
    .lfsr_enable       (lfsr_enable),
    .output_data_select(output_data_select),
    .data_out_valid    (data_out_valid),
    .encoding_done     (encoding_done),
    .ready_for_data    (ready_for_data),
    .counter_clear     (counter_clear),
    .counter_enable    (counter_enable)
);

//========================= Clock Generation ==============================
initial clk = 0;
always #5 clk = ~clk;  // 100MHz clock

//========================= Counter Simulation ============================
// Simulate counter behavior based on FSM outputs
always @(posedge clk) begin
    if (!rst || counter_clear)
        counter_tb <= 8'd0;
    else if (counter_enable)
        counter_tb <= counter_tb + 8'd1;
end

//========================= Signal Monitor ================================
initial begin
    $display("=================================================");
    $display("         Encoder FSM Testbench Starting          ");
    $display("=================================================");
    $display("Time | State         | Cnt | DV | LE | ODS | DOV | Done | RFD | CC | CE");
    $display("----|--------------|-----|----|----|-----|-----|------|-----|----|----|");
end

always @(posedge clk) begin
    $display("%4t | %s | %3d | %b  | %b  | %b   | %b   | %b    | %b   | %b  | %b",
        $time,
        state_name,
        counter_tb,
        data_valid,
        lfsr_enable,
        output_data_select,
        data_out_valid,
        encoding_done,
        ready_for_data,
        counter_clear,
        counter_enable
    );
end

//========================= Main Test =====================================
initial begin
    // Initialize signals
    rst          = 1'b0;
    start_encode = 1'b0;
    data_valid   = 1'b0;

    //---------------------------------------------
    // Test 1: Reset Behavior
    //---------------------------------------------
    $display("\n--- Test 1: Reset Behavior ---");
    @(posedge clk); #1;
    rst = 1'b0;
    repeat(3) @(posedge clk); #1;
    
    // Check IDLE state after reset
    if (current_state !== 3'b000)
        $display("FAIL: Expected IDLE after reset, got %b", current_state);
    else
        $display("PASS: FSM in IDLE after reset");

    if (ready_for_data !== 1'b1)
        $display("FAIL: ready_for_data should be 1 in IDLE");
    else
        $display("PASS: ready_for_data=1 in IDLE");

    //---------------------------------------------
    // Test 2: IDLE to INIT Transition
    //---------------------------------------------
    $display("\n--- Test 2: IDLE to INIT Transition ---");
    rst = 1'b1;
    @(posedge clk); #1;
    start_encode = 1'b1;
    @(posedge clk); #1;
    start_encode = 1'b0;

    // Should be in INIT now
    if (current_state !== 3'b011)
        $display("FAIL: Expected INIT state, got %b", current_state);
    else
        $display("PASS: FSM in INIT state");

    // Check INIT outputs
    if (lfsr_clear !== 1'b1)
        $display("FAIL: lfsr_clear should be 1 in INIT");
    else
        $display("PASS: lfsr_clear=1 in INIT");

    if (counter_clear !== 1'b1)
        $display("FAIL: counter_clear should be 1 in INIT");
    else
        $display("PASS: counter_clear=1 in INIT");

    //---------------------------------------------
    // Test 3: INIT to OUTPUT_DATA Transition
    //---------------------------------------------
    $display("\n--- Test 3: INIT to OUTPUT_DATA Transition ---");
    @(posedge clk); #1;

    if (current_state !== 3'b001)
        $display("FAIL: Expected OUTPUT_DATA, got %b", current_state);
    else
        $display("PASS: FSM in OUTPUT_DATA state");

    //---------------------------------------------
    // Test 4: OUTPUT_DATA - No data_valid
    //---------------------------------------------
    $display("\n--- Test 4: OUTPUT_DATA with data_valid=0 ---");
    data_valid = 1'b0;
    @(posedge clk); #1;

    if (lfsr_enable !== 1'b0)
        $display("FAIL: lfsr_enable should be 0 when data_valid=0");
    else
        $display("PASS: lfsr_enable=0 when data_valid=0");

    if (counter_enable !== 1'b0)
        $display("FAIL: counter_enable should be 0 when data_valid=0");
    else
        $display("PASS: counter_enable=0 when data_valid=0");

    //---------------------------------------------
    // Test 5: OUTPUT_DATA - With data_valid
    //---------------------------------------------
    $display("\n--- Test 5: OUTPUT_DATA with data_valid=1 ---");
    data_valid = 1'b1;
    @(posedge clk); #1;

    if (lfsr_enable !== 1'b1)
        $display("FAIL: lfsr_enable should be 1 when data_valid=1");
    else
        $display("PASS: lfsr_enable=1 when data_valid=1");

    if (counter_enable !== 1'b1)
        $display("FAIL: counter_enable should be 1 when data_valid=1");
    else
        $display("PASS: counter_enable=1 when data_valid=1");

    if (output_data_select !== 1'b0)
        $display("FAIL: output_data_select should be 0 in OUTPUT_DATA");
    else
        $display("PASS: output_data_select=0 in OUTPUT_DATA");

    if (data_out_valid !== 1'b1)
        $display("FAIL: data_out_valid should be 1 when data_valid=1");
    else
        $display("PASS: data_out_valid=1 when data_valid=1");

    //---------------------------------------------
    // Test 6: Run through all k=223 data bytes
    //---------------------------------------------
    $display("\n--- Test 6: Processing all %0d data bytes ---", k);
    data_valid = 1'b1;

    // Wait until counter reaches k-1 (222)
    // counter already at 1 from Test 5
    // Need (k-1 - current_count) more cycles
    repeat(k - 3) @(posedge clk); #1;  // -3 accounts for cycles used above

    // Should transition to OUTPUT_PARITY
    @(posedge clk); #1;

    if (current_state !== 3'b010)
        $display("FAIL: Expected OUTPUT_PARITY after %0d bytes, got %b", k, current_state);
    else
        $display("PASS: FSM transitioned to OUTPUT_PARITY after %0d data bytes", k);

    //---------------------------------------------
    // Test 7: OUTPUT_PARITY State Outputs
    //---------------------------------------------
    $display("\n--- Test 7: OUTPUT_PARITY Outputs ---");

    if (output_data_select !== 1'b1)
        $display("FAIL: output_data_select should be 1 in OUTPUT_PARITY");
    else
        $display("PASS: output_data_select=1 in OUTPUT_PARITY");

    if (data_out_valid !== 1'b1)
        $display("FAIL: data_out_valid should be 1 in OUTPUT_PARITY");
    else
        $display("PASS: data_out_valid=1 in OUTPUT_PARITY");

    if (counter_enable !== 1'b1)
        $display("FAIL: counter_enable should be 1 in OUTPUT_PARITY");
    else
        $display("PASS: counter_enable=1 in OUTPUT_PARITY");

    //---------------------------------------------
    // Test 8: Run through all 2*t=32 parity bytes
    //---------------------------------------------
    $display("\n--- Test 8: Processing all %0d parity bytes ---", 2*t);

    // Wait until encoding_done
    repeat(2*t - 1) @(posedge clk); #1;

    if (encoding_done !== 1'b1)
        $display("FAIL: encoding_done should be 1 at end of parity");
    else
        $display("PASS: encoding_done=1 at end of parity output");

    @(posedge clk); #1;

    //---------------------------------------------
    // Test 9: Return to IDLE
    //---------------------------------------------
    $display("\n--- Test 9: Return to IDLE ---");

    if (current_state !== 3'b000)
        $display("FAIL: Expected IDLE after encoding, got %b", current_state);
    else
        $display("PASS: FSM returned to IDLE after encoding");

    if (ready_for_data !== 1'b1)
        $display("FAIL: ready_for_data should be 1 in IDLE");
    else
        $display("PASS: ready_for_data=1 in IDLE");

    //---------------------------------------------
    // Test 10: Back-to-Back Encoding
    //---------------------------------------------
    $display("\n--- Test 10: Back-to-Back Encoding ---");
    @(posedge clk); #1;
    start_encode = 1'b1;
    @(posedge clk); #1;
    start_encode = 1'b0;

    if (current_state !== 3'b011)
        $display("FAIL: Expected INIT for second encoding");
    else
        $display("PASS: Second encoding started correctly");

    //---------------------------------------------
    // Test 11: Mid-encoding Reset
    //---------------------------------------------
    $display("\n--- Test 11: Mid-encoding Reset ---");
    @(posedge clk); #1;  // Move to OUTPUT_DATA
    data_valid = 1'b1;
    repeat(10) @(posedge clk); #1;  // Process 10 bytes

    rst = 1'b0;  // Assert reset mid-encoding
    @(posedge clk); #1;
    rst = 1'b1;

    if (current_state !== 3'b000)
        $display("FAIL: Expected IDLE after mid-encoding reset");
    else
        $display("PASS: FSM correctly resets to IDLE mid-encoding");

    //---------------------------------------------
    // Test 12: data_valid Intermittent
    //---------------------------------------------
    $display("\n--- Test 12: Intermittent data_valid ---");
    @(posedge clk); #1;
    start_encode = 1'b1;
    @(posedge clk); #1;
    start_encode = 1'b0;
    @(posedge clk); #1;  // INIT -> OUTPUT_DATA

    // Toggle data_valid
    repeat(5) begin
        data_valid = 1'b1;
        @(posedge clk); #1;
        data_valid = 1'b0;
        @(posedge clk); #1;
        $display("Counter during intermittent valid: %0d", counter_tb);
    end

    // Verify counter only incremented when data_valid=1
    if (counter_tb == 5)
        $display("PASS: Counter correctly incremented only with data_valid=1");
    else
        $display("FAIL: Counter=%0d, expected 5 with intermittent data_valid", counter_tb);

    //---------------------------------------------
    // End of Tests
    //---------------------------------------------
    $display("\n=================================================");
    $display("           All Tests Complete                    ");
    $display("=================================================");
    
    repeat(5) @(posedge clk);
    $finish;
end

//========================= Timeout Watchdog ==============================
initial begin
    #500000;  // 500us timeout
    $display("TIMEOUT: Simulation exceeded time limit!");
    $finish;
end

//========================= Waveform Dump =================================
initial begin
    $dumpfile("encoder_fsm_tb.vcd");
    $dumpvars(0, encoder_fsm_tb);
end

endmodule