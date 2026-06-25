`timescale 1ns/1ps

module dvb_top_tb;

    // ===================== Parameters =====================
    localparam BLOCK_LENGTH = 128;
    localparam CLK_PERIOD   = 10;   // clk_sample period, ns

    // ===================== DUT signals =====================
    reg                          clk_sample;
    reg                          rst;
    reg  [BLOCK_LENGTH-1:0]      plaintext_in;
    reg  [BLOCK_LENGTH-1:0]      aes_key;
    reg                          aes_fsm_en;

    wire signed [15:0]           I_out;
    wire signed [15:0]           Q_out;
    wire [3:0]                   period_count_o;
    wire [2:0]                   rs_current_state_o;

    // ===================== DUT instantiation =====================
    dvb_top #(
        .BLOCK_LENGTH (BLOCK_LENGTH),
        .RS_M (8), .RS_K (192), .RS_N (208), .RS_T (8)
    ) dut (
        .clk_sample          (clk_sample),
        .rst                 (rst),
        .plaintext_in        (plaintext_in),
        .aes_key             (aes_key),
        .aes_fsm_en          (aes_fsm_en),
        .I_out               (I_out),
        .Q_out               (Q_out),
        .period_count_o      (period_count_o),
        .rs_current_state_o  (rs_current_state_o)
    );

    // ===================== Clock generation =====================
    initial clk_sample = 1'b0;
    always #(CLK_PERIOD/2) clk_sample = ~clk_sample;

    // ===================== Stimulus =====================
    // Timing notes (see chat derivation):
    //   - 1 symbol_tick = 4 clk_sample cycles
    //   - key schedule needs ~11 symbol_ticks once aes_fsm_en is seen
    //   - dvb_master_fsm starts its cyc/period counters the instant rst
    //     deasserts, so the very first AES block (period 1) will be
    //     encrypted with a still-loading key - accepted as known/expected
    //     per your decision; check correctness from period 1 of the
    //     SECOND codeword (i.e. roughly symbol_tick 416) onward.

    initial begin
        rst          = 1'b0;
        plaintext_in = 128'h00112233445566778899AABBCCDDEEFF;
        aes_key      = 128'h000102030405060708090A0B0C0D0E0F;
        aes_fsm_en   = 1'b0;

        // Hold reset for a few clk_sample cycles
        repeat (8) @(posedge clk_sample);

        // Release reset - dvb_master_fsm's cyc/period counters start now,
        // and AES_enc's internal FSM is also free to leave IDLE now.
        rst = 1'b1;

        // Pulse aes_fsm_en for >= 1 full symbol_tick window (4 clk_sample
        // edges) so the symbol_tick-gated FSM register inside AES_enc
        // reliably samples it as high on a real tick, not just glimpsing
        // it on one of the 3 "idle" clk_sample edges between ticks.
        @(posedge clk_sample);
        aes_fsm_en = 1'b1;
        repeat (8) @(posedge clk_sample);   // held for 2 full symbol_ticks of margin
        aes_fsm_en = 1'b0;

        // Let the simulation run long enough to observe at least two full
        // 13-period codewords (1664 clk_sample cycles each) plus startup
        // margin, so block-2-onward behavior (the first "clean" block) is
        // visible along with a full second codeword for repeatability checks.
        repeat (3600) @(posedge clk_sample);

        $display("Simulation finished at time %0t", $time);
        $finish;
    end

    // ===================== Monitoring =====================
    // Prints a line every time the master FSM's period counter changes,
    // so you can see the codeword structure (12 data periods + 1 parity
    // period) advancing in the transcript without needing a waveform
    // viewer open. Also dumps full waveforms below for GTKWave/similar.
    reg [3:0] period_prev;
    initial period_prev = 4'd0;

    always @(posedge clk_sample) begin
        if (rst && period_count_o !== period_prev) begin
            $display("t=%0t  period -> %0d  (rs_current_state=%0d)",
                      $time, period_count_o, rs_current_state_o);
            period_prev <= period_count_o;
        end
    end

    // Dump waveforms for GTKWave / similar viewers
    initial begin
        $dumpfile("dvb_top_tb.vcd");
        $dumpvars(0, dvb_top_tb);
    end

endmodule