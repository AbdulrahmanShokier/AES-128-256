//==============================================================================
// Testbench: key_generator_tb
// Description: Verifies AES-128 key expansion against known test vectors
// Reference: NIST FIPS-197 Appendix A.1
//==============================================================================
`timescale 1ns / 1ps

module key_generator_tb;

    //==========================================================================
    // Parameters
    //==========================================================================
    parameter CLK_PERIOD = 10;  // 100 MHz
    parameter BLOCK_LENGTH = 128;

    //==========================================================================
    // DUT Signals
    //==========================================================================
    reg                      clk;
    reg                      rst;
    reg                      en;
    reg  [BLOCK_LENGTH-1:0]  key;
    reg  [3:0]               Round_Count;
    wire [BLOCK_LENGTH-1:0]  current_key;
    //==========================================================================
    // Expected Round Keys (NIST FIPS-197 Appendix A.1)
    // Initial Key: 128'h2b7e151628aed2a6abf7158809cf4f3c
    //==========================================================================
    reg [127:0] expected_keys [0:10];

    initial begin
        expected_keys[0]  = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        expected_keys[1]  = 128'ha0fafe1788542cb123a339392a6c7605;
        expected_keys[2]  = 128'hf2c295f27a96b9435935807a7359f67f;
        expected_keys[3]  = 128'h3d80477d4716fe3e1e237e446d7a883b;
        expected_keys[4]  = 128'hef44a541a8525b7fb671253bdb0bad00;
        expected_keys[5]  = 128'hd4d1c6f87c839d87caf2b8bc11f915bc;
        expected_keys[6]  = 128'h6d88a37a110b3efddbf98641ca0093fd;
        expected_keys[7]  = 128'h4e54f70e5f5fc9f384a64fb24ea6dc4f;
        expected_keys[8]  = 128'head27321b58dbad2312bf5607f8d292f;
        expected_keys[9]  = 128'hac7766f319fadc2128d12941575c006e;
        expected_keys[10] = 128'hd014f9a8c9ee2589e13f0cc8b6630ca6;
    end

    //==========================================================================
    // DUT Instantiation
    //==========================================================================
    key_generator #(
        .BLOCK_LENGTH(BLOCK_LENGTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .key(key),
        .Round_Count(Round_Count),
        .current_key(current_key)
    );

    //==========================================================================
    // Clock Generation
    //==========================================================================
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    //==========================================================================
    // Test Tracking
    //==========================================================================
    integer pass_count;
    integer fail_count;
    integer i;

    //==========================================================================
    // Helper Tasks
    //==========================================================================

    task reset_dut;
        begin
            rst         = 1'b0;
            en          = 1'b0;
            key         = 128'b0;
            Round_Count = 4'd0;
            @(posedge clk);
            @(posedge clk);
            rst = 1'b1;
            @(posedge clk);
        end
    endtask

    task check_key;
        input [3:0]   round;
        input [127:0] expected;
        begin
            if (current_key === expected) begin
                $display("[PASS] Round %0d: key = %h", round, current_key);
                pass_count = pass_count + 1;
            end
            else begin
                $display("[FAIL] Round %0d:", round);
                $display("       Expected: %h", expected);
                $display("       Got:      %h", current_key);
                fail_count = fail_count + 1;
            end
        end
    endtask

    //==========================================================================
    // Test Scenarios
    //==========================================================================

    initial begin
        // ── Initialize ──
        $display("==================================================");
        $display("  AES-128 Key Generator Testbench");
        $display("==================================================");
        pass_count = 0;
        fail_count = 0;

        // ──────────────────────────────────────────────────
        // TEST 1: Reset Verification
        // ──────────────────────────────────────────────────
        $display("\n--- TEST 1: Reset Verification ---");
        reset_dut;

        if (current_key === 128'b0 ) begin
            $display("[PASS] Reset: current_key = 0");
            pass_count = pass_count + 1;
        end
        else begin
            $display("[FAIL] Reset state incorrect");
            $display("       current_key = %h", current_key);
            fail_count = fail_count + 1;
        end

        // ──────────────────────────────────────────────────
        // TEST 2: NIST Test Vector Key Expansion
        // Key: 2b7e151628aed2a6abf7158809cf4f3c
        // ──────────────────────────────────────────────────
        $display("\n--- TEST 2: NIST FIPS-197 Key Expansion ---");
        reset_dut;

        key = 128'h2b7e151628aed2a6abf7158809cf4f3c;

        // Round 0: Load initial key
        en          = 1'b1;
        Round_Count = 4'd0;
        @(posedge clk);
        #1;
        check_key(4'd0, expected_keys[0]);

        // Rounds 1-10: Generate expansion keys
        for (i = 1; i <= 10; i = i + 1) begin
            Round_Count = i[3:0];
            @(posedge clk);
            #1;
            check_key(i[3:0], expected_keys[i]);
        end


        // ──────────────────────────────────────────────────
        // TEST 4: Reset mid-operation
        // ──────────────────────────────────────────────────
        $display("\n--- TEST 4: Reset Mid-Operation ---");
        // Start key expansion
        en          = 1'b1;
        key         = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        Round_Count = 4'd0;
        @(posedge clk);
        Round_Count = 4'd1;
        @(posedge clk);
        Round_Count = 4'd2;
        @(posedge clk);

        // Assert reset mid-operation
        rst = 1'b0;
        @(posedge clk);
        #1;

        if (current_key === 128'b0 ) begin
            $display("[PASS] Mid-operation reset: state cleared");
            pass_count = pass_count + 1;
        end
        else begin
            $display("[FAIL] Mid-operation reset failed");
            fail_count = fail_count + 1;
        end

        // Resume after reset
        rst = 1'b1;
        @(posedge clk);

        // ──────────────────────────────────────────────────
        // TEST 5: Second NIST Test Vector
        // Key: 000102030405060708090a0b0c0d0e0f
        // ──────────────────────────────────────────────────
        $display("\n--- TEST 5: Second Test Vector ---");
        reset_dut;

        key = 128'h000102030405060708090a0b0c0d0e0f;

        en          = 1'b1;
        Round_Count = 4'd0;
        @(posedge clk);
        #1;

        if (current_key === 128'h000102030405060708090a0b0c0d0e0f) begin
            $display("[PASS] Round 0: Initial key loaded correctly");
            pass_count = pass_count + 1;
        end
        else begin
            $display("[FAIL] Round 0: key = %h", current_key);
            fail_count = fail_count + 1;
        end

        // Round 1 expected: d6aa74fdd2af72fadaa678f1d6ab76fe
        Round_Count = 4'd1;
        @(posedge clk);
        #1;

        if (current_key === 128'hd6aa74fdd2af72fadaa678f1d6ab76fe) begin
            $display("[PASS] Round 1: key = %h", current_key);
            pass_count = pass_count + 1;
        end
        else begin
            $display("[FAIL] Round 1: Expected d6aa74fdd2af72fadaa678f1d6ab76fe");
            $display("               Got      %h", current_key);
            fail_count = fail_count + 1;
        end

        // Round 2 expected: b692cf0b643dbdf1be9bc5006830b3fe
        Round_Count = 4'd2;
        @(posedge clk);
        #1;

        if (current_key === 128'hb692cf0b643dbdf1be9bc5006830b3fe) begin
            $display("[PASS] Round 2: key = %h", current_key);
            pass_count = pass_count + 1;
        end
        else begin
            $display("[FAIL] Round 2: Expected b692cf0b643dbdf1be9bc5006830b3fe");
            $display("               Got      %h", current_key);
            fail_count = fail_count + 1;
        end

        // ──────────────────────────────────────────────────
        // TEST 6: Enable gating (en=0 holds state)
        // ──────────────────────────────────────────────────
        $display("\n--- TEST 6: Enable Gating ---");
        reset_dut;

        key         = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        en          = 1'b1;
        Round_Count = 4'd0;
        @(posedge clk);
        #1;

        // Disable enable, key should hold
        en = 1'b0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        #1;

        if (current_key === expected_keys[0]) begin
            $display("[PASS] Key held stable when en = 0");
            pass_count = pass_count + 1;
        end
        else begin
            $display("[FAIL] Key changed when en = 0: %h", current_key);
            fail_count = fail_count + 1;
        end

        // ──────────────────────────────────────────────────
        // RESULTS SUMMARY
        // ──────────────────────────────────────────────────
        $display("\n==================================================");
        $display("  TEST RESULTS");
        $display("==================================================");
        $display("  PASSED: %0d", pass_count);
        $display("  FAILED: %0d", fail_count);
        $display("  TOTAL:  %0d", pass_count + fail_count);
        $display("==================================================");

        if (fail_count == 0)
            $display("  >>> ALL TESTS PASSED <<<");
        else
            $display("  >>> SOME TESTS FAILED <<<");

        $display("==================================================\n");
        $finish;
    end

    //==========================================================================
    // Waveform Dump
    //==========================================================================
    initial begin
        $dumpfile("key_generator_tb.vcd");
        $dumpvars(0, key_generator_tb);
    end

    //==========================================================================
    // Timeout Watchdog
    //==========================================================================
    initial begin
        #(CLK_PERIOD * 500);
        $display("[ERROR] Simulation timeout!");
        $finish;
    end

endmodule