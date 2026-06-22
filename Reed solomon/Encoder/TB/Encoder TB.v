`timescale 1ns/1ps

module tb_encoder_top;


//========================= Parameters =============================
parameter m = 8;
parameter k = 192;
parameter n = 208;
parameter t = 8;

//========================= Signals ================================
reg              clk;
reg              rst;
reg  [m-1:0]     data_in;
reg              start_encode;
reg              data_valid;

wire [m-1:0]     data_out;
wire             data_out_valid;
wire             encoding_done;
wire             ready_for_data;

// Internal observation
wire [2:0]       current_state;
wire             lfsr_clear;
wire             lfsr_enable;
wire             output_data_select;
wire             counter_clear;
wire             counter_enable;
wire [7:0]       counter;

//========================= DUT: Encoder Core ======================
encoder_core #(
    .m(m),
    .k(k),
    .t(t)
) core_inst (
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

//========================= DUT: Encoder FSM =======================
encoder_fsm #(
    .k(k),
    .n(n),
    .t(t)
) fsm_inst (
    .clk               (clk),
    .rst               (rst),
    .start_encode      (start_encode),
    .data_valid        (data_valid),
    .counter           (counter),
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

//========================= Clock ==================================
initial clk = 0;
always #5 clk = ~clk;

//========================= State Name =============================
reg [127:0] state_name;
always @(*) begin
    case(current_state)
        3'b000: state_name = "IDLE         ";
        3'b011: state_name = "INIT         ";
        3'b001: state_name = "OUTPUT_DATA  ";
        3'b010: state_name = "OUTPUT_PARITY";
        default: state_name = "UNKNOWN      ";
    endcase
end

//========================= Expected Parity ========================
// MATLAB expected parity for msg = [1, 0, 0, ..., 0]  (impulse = 1, NOT 255)
reg [m-1:0] expected_parity [0:2*t-1];
initial begin
    expected_parity[0]  = 8'd48  ;
    expected_parity[1]  = 8'd8   ;
    expected_parity[2]  = 8'd187 ;
    expected_parity[3]  = 8'd76  ;
    expected_parity[4]  = 8'd175 ;
    expected_parity[5]  = 8'd149 ;
    expected_parity[6]  = 8'd238 ;
    expected_parity[7]  = 8'd232 ;
    expected_parity[8]  = 8'd127 ;
    expected_parity[9]  = 8'd7   ;
    expected_parity[10] = 8'd149 ;
    expected_parity[11] = 8'd113 ;
    expected_parity[12] = 8'd139 ;
    expected_parity[13] = 8'd17  ;
    expected_parity[14] = 8'd1   ;
    expected_parity[15] = 8'd83  ;
end

//========================= Result Storage =========================
reg [m-1:0] captured_data   [0:k-1];
reg [m-1:0] captured_parity [0:2*t-1];
integer      data_count;
integer      parity_count;
integer      error_count;
integer      i;

// Stall-test bookkeeping
integer      stall_cycles_seen;
integer      counter_before_stall;
integer      counter_after_stall;

//========================= Capture Output =========================
always @(posedge clk) begin
    if (!rst) begin
        data_count   <= 0;
        parity_count <= 0;
    end
    else if (data_out_valid) begin
        if (!output_data_select) begin
            captured_data[data_count] <= data_out;
            data_count <= data_count + 1;
        end
        else begin
            captured_parity[parity_count] <= data_out;
            parity_count <= parity_count + 1;
        end
    end
end

//========================= Main Test ==============================
initial begin
    // Initialize
    rst          = 0;
    data_in      = 0;
    start_encode = 0;
    data_valid   = 0;

    // Reset
    repeat(5) @(posedge clk); #1;
    rst = 1;
    repeat(2) @(posedge clk); #1;

    $display("==============================================");
    $display("  Full RS(208,192) Encoder Testbench");
    $display("  Input: msg = [1, 0, 0, ..., 0]");
    $display("==============================================\n");

    //--------------------------------------------------
    // Start encoding
    //--------------------------------------------------
    $display(">>> Starting encoder...");
    start_encode = 1;
    @(posedge clk); #1;
    start_encode = 0;

    // Wait for INIT state
    @(posedge clk); #1;
    $display("State: %s", state_name);

    // Wait for OUTPUT_DATA state
    @(posedge clk); #1;
    $display("State: %s", state_name);

    //--------------------------------------------------
    // Phase 1: Feed k data bytes, WITH a stall partway through
    //--------------------------------------------------
    $display("\n>>> Phase 1: Feeding %0d data bytes (with a mid-stream stall)...", k);

    for (i = 0; i < k; i = i + 1) begin
        // First byte = 1, rest = 0 (impulse test vector)
        if (i == 0)
            data_in = 8'd1;
        else
            data_in = 8'd0;

        data_valid = 1;
        @(posedge clk); #1;

        // Print first few cycles
        if (i < 3) begin
            $display("  Cycle %0d: data_in=%3d, counter=%3d, state=%s, feedback=%3d",
                i, data_in, counter, state_name, core_inst.feedback);
        end

        //----------------------------------------------
        // Inject a stall: pause data_valid for a few clocks
        // partway through the data phase (e.g. right after
        // byte index 50), then resume.
        //----------------------------------------------
        if (i == 50) begin
            counter_before_stall = counter;
            $display("\n  >>> STALL TEST: pausing data_valid at i=%0d (counter=%0d)",
                i, counter);

            data_valid = 0;
            data_in    = 0;

            stall_cycles_seen = 0;
            repeat (4) begin
                @(posedge clk); #1;
                stall_cycles_seen = stall_cycles_seen + 1;
                $display("    stall cycle %0d: counter=%3d (should be unchanged), state=%s, lfsr_enable=%b, counter_enable=%b",
                    stall_cycles_seen, counter, state_name, lfsr_enable, counter_enable);

                if (counter !== counter_before_stall) begin
                    $display("    *** FAIL: counter changed during stall! expected %0d, got %0d ***",
                        counter_before_stall, counter);
                end
            end

            counter_after_stall = counter;
            if (counter_after_stall == counter_before_stall)
                $display("  >>> STALL TEST: counter correctly held at %0d during pause. PASS",
                    counter_before_stall);
            else
                $display("  >>> STALL TEST: counter did NOT hold steady. FAIL (before=%0d, after=%0d)",
                    counter_before_stall, counter_after_stall);

            $display("  >>> STALL TEST: resuming data_valid...\n");
            // data_valid will be reasserted at the top of the next loop iteration
        end
    end

    data_valid = 0;
    data_in    = 0;

    $display("  ... (data feeding complete)");
    $display("  Counter after data phase: %0d", counter);
    $display("  State: %s", state_name);

    //--------------------------------------------------
    // Print LFSR state before parity output
    //--------------------------------------------------
    $display("\n>>> LFSR State after data phase:");
    for (i = 0; i < 16; i = i + 4)
        $display("  %2d : %3d %3d %3d %3d", i,
            core_inst.lfsr_regs[i],
            core_inst.lfsr_regs[i+1],
            core_inst.lfsr_regs[i+2],
            core_inst.lfsr_regs[i+3]);

    //--------------------------------------------------
    // Phase 2: Wait for parity output
    //--------------------------------------------------
    $display("\n>>> Phase 2: Reading parity bytes...");

    // Wait for all parity bytes + encoding_done
    while (!encoding_done) begin
        @(posedge clk); #1;
    end

    // Wait one more cycle for last capture
    @(posedge clk); #1;

    //--------------------------------------------------
    // Print and verify captured data
    //--------------------------------------------------
    $display("\n>>> Captured Data Bytes (first 5 and last 5):");
    for (i = 0; i < 5; i = i + 1)
        $display("  Data[%3d] = %3d", i, captured_data[i]);
    $display("  ...");
    for (i = k-5; i < k; i = i + 1)
        $display("  Data[%3d] = %3d", i, captured_data[i]);

    //--------------------------------------------------
    // Print and verify parity
    //--------------------------------------------------
    $display("\n>>> Parity Comparison:");
    $display("Index | Got | Expected | Match");
    $display("------|-----|----------|------");

    error_count = 0;
    for (i = 0; i < 2*t; i = i + 1) begin
        if (captured_parity[i] !== expected_parity[i]) begin
            $display("  %2d  | %3d |   %3d    |  FAIL <<<",
                i, captured_parity[i], expected_parity[i]);
            error_count = error_count + 1;
        end
        else begin
            $display("  %2d  | %3d |   %3d    |  PASS",
                i, captured_parity[i], expected_parity[i]);
        end
    end

    //--------------------------------------------------
    // Final Result
    //--------------------------------------------------
    $display("\n==============================================");
    if (error_count == 0)
        $display("  RESULT: ALL %0d PARITY BYTES CORRECT (stall test included)!", 2*t);
    else
        $display("  RESULT: %0d PARITY BYTES FAILED!", error_count);
    $display("  Total data bytes captured:   %0d", data_count);
    $display("  Total parity bytes captured: %0d", parity_count);
    $display("==============================================\n");

    repeat(5) @(posedge clk);
    $finish;
end

//========================= Debug Monitor ==========================
// Uncomment to see every clock cycle
// always @(posedge clk) begin
//     $display("T=%4t | State=%s | Cnt=%3d | DV=%b | DOV=%b | ODS=%b | LE=%b | CE=%b | din=%3d | dout=%3d | pidx=%3d",
//         $time, state_name, counter, data_valid, data_out_valid,
//         output_data_select, lfsr_enable, counter_enable,
//         data_in, data_out, core_inst.parity_index_reg);
// end

//========================= Waveform Dump ==========================


//========================= Timeout ================================
initial begin
    #1000000;
    $display("TIMEOUT!");
    $finish;
end

endmodule