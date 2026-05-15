// =============================================================================
//  tb_crc32_dvb.v  —  Testbench for crc32_dvb
//
//  Configuration:
//    DATA_W  = 32  (32 bits processed per clock)
//    Frame   = 42784 bits = 1337 words of 32 bits = 5348 bytes
//    CRC     = 32-bit DVB CRC-32 (polynomial 0x04C11DB7, init 0xFFFFFFFF)
//
//  Tests:
//    1. Known-good vector: CRC-32 of "123456789" → expect 0x0376E6E7
//       (reference model only — 9 bytes is not a multiple of 32 bits)
//    2. Full 42784-bit frame (1337 x 32-bit words) — DUT vs byte-serial ref
//    3. Back-to-back frames — SOF resets state correctly between frames
//    4. valid de-assert mid-frame — DUT holds state during gaps
//    5. eof + valid same cycle — last word included in CRC correctly
//
//  Run with:
//    vcs  -sverilog crc32_parallel.v tb_crc32_dvb.v -o sim && ./sim
//    vsim -do "vsim work.tb_crc32_dvb; run -all"
// =============================================================================

`timescale 1ns/1ps

module tb_crc32_dvb;

    // -------------------------------------------------------------------------
    // Parameters
    // -------------------------------------------------------------------------
    parameter DATA_W      = 32;
    parameter FRAME_BITS  = 42784;
    parameter FRAME_WORDS = FRAME_BITS / DATA_W;    // 1337
    parameter FRAME_BYTES = FRAME_BITS / 8;         // 5348

    // -------------------------------------------------------------------------
    // DUT ports
    // -------------------------------------------------------------------------
    reg               clk, rst_n;
    reg               sof, valid, eof;
    reg  [DATA_W-1:0] data_in;
    wire [31:0]       crc_out;
    wire              crc_valid;

    crc32_dvb #(.DATA_W(DATA_W)) dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .sof      (sof),
        .valid    (valid),
        .data_in  (data_in),
        .eof      (eof),
        .crc_out  (crc_out),
        .crc_valid(crc_valid)
    );

    // 10 ns clock
    initial clk = 0;
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // Pass / fail counters
    // -------------------------------------------------------------------------
    integer pass_count;
    integer fail_count;

    // -------------------------------------------------------------------------
    // Byte-serial reference model
    // Processes one byte MSB-first — used to build the golden CRC for any
    // byte sequence, then compared against the parallel DUT result.
    // -------------------------------------------------------------------------
    function automatic [31:0] crc32_byte;
        input [31:0] crc_in;
        input [7:0]  byte_in;
        integer i;
        reg [31:0] c;
        reg        fb;
        begin
            c = crc_in;
            for (i = 7; i >= 0; i = i - 1) begin
                fb = c[31] ^ byte_in[i];
                c  = {c[30:0], 1'b0} ^ (fb ? 32'h04C11DB7 : 32'h0);
            end
            crc32_byte = c;
        end
    endfunction

    // -------------------------------------------------------------------------
    // Helper: drive one DATA_W-bit word into the DUT.
    // Applies signals after the rising edge (#1 delay avoids hold violations).
    // -------------------------------------------------------------------------
    task drive_word;
        input [DATA_W-1:0] word;
        input              is_sof;
        input              is_eof;
        begin
            @(posedge clk); #1;
            data_in = word;
            valid   = 1;
            sof     = is_sof;
            eof     = is_eof;
        end
    endtask

    // -------------------------------------------------------------------------
    // Helper: idle for N cycles (valid=0, state_r must hold)
    // -------------------------------------------------------------------------
    task idle_cycles;
        input integer n;
        integer k;
        begin
            for (k = 0; k < n; k = k + 1) begin
                @(posedge clk); #1;
                valid = 0;
                sof   = 0;
                eof   = 0;
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Helper: wait up to 10 cycles for crc_valid, return captured result.
    // Sets timed_out=1 and prints an error if it never asserts.
    // -------------------------------------------------------------------------
    task wait_crc_valid;
        output [31:0] result;
        output        timed_out;
        integer       watchdog;
        begin
            @(posedge clk); #1;
            valid     = 0;
            eof       = 0;
            timed_out = 0;
            watchdog  = 0;
            while (!crc_valid && watchdog < 10) begin
                @(posedge clk); #1;
                watchdog = watchdog + 1;
            end
            if (!crc_valid) begin
                $display("  ERROR: crc_valid never asserted after eof");
                timed_out = 1;
                result    = 32'hDEADBEEF;
            end else begin
                result = crc_out;
            end
        end
    endtask

    // =========================================================================
    // TEST 1 — Known-good vector: CRC-32("123456789") = 0x0376E6E7
    //
    // 9 bytes is not a multiple of 32 bits so the DUT cannot be driven
    // directly without padding. We verify the reference model only — this
    // confirms the polynomial, bit order, and init value are all correct
    // before trusting any DUT comparison in later tests.
    // =========================================================================
    task test_known_vector;
        integer    i;
        reg [31:0] ref_crc;
        reg [7:0]  test_bytes [0:8];
        begin
            $display("----------------------------------------------------------");
            $display("TEST 1: Known-good vector CRC-32('123456789')");

            test_bytes[0] = 8'h31; test_bytes[1] = 8'h32; test_bytes[2] = 8'h33;
            test_bytes[3] = 8'h34; test_bytes[4] = 8'h35; test_bytes[5] = 8'h36;
            test_bytes[6] = 8'h37; test_bytes[7] = 8'h38; test_bytes[8] = 8'h39;

            ref_crc = 32'hFFFFFFFF;
            for (i = 0; i < 9; i = i + 1)
                ref_crc = crc32_byte(ref_crc, test_bytes[i]);

            $display("  Reference model result : 0x%08X", ref_crc);

            if (ref_crc === 32'h0376E6E7) begin
                $display("  PASS — polynomial 0x04C11DB7 and init 0xFFFFFFFF confirmed");
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL — reference model broken (got 0x%08X, expect 0x0376E6E7)", ref_crc);
                fail_count = fail_count + 1;
            end

            $display("  NOTE: 9 bytes is not a multiple of %0d bits, DUT not driven.", DATA_W);
        end
    endtask

    // =========================================================================
    // TEST 2 — Full 42784-bit DVB frame (1337 x 32-bit words = 5348 bytes)
    //
    // Fills the frame with a deterministic pseudo-random pattern, computes
    // reference CRC byte-serially, drives DUT word-by-word, and compares.
    // =========================================================================
    task test_full_frame;
        integer          i, b;
        reg [7:0]        frame_bytes [0:FRAME_BYTES-1];
        reg [DATA_W-1:0] word;
        reg [31:0]       ref_crc;
        reg [31:0]       dut_crc;
        reg              timed_out;
        begin
            $display("----------------------------------------------------------");
            $display("TEST 2: Full %0d-bit frame (%0d words x %0d bits)",
                     FRAME_BITS, FRAME_WORDS, DATA_W);

            // Pseudo-random payload
            for (i = 0; i < FRAME_BYTES; i = i + 1)
                frame_bytes[i] = ((i * 37 + 13) ^ (i >> 3)) & 8'hFF;

            // Reference (byte-serial)
            ref_crc = 32'hFFFFFFFF;
            for (i = 0; i < FRAME_BYTES; i = i + 1)
                ref_crc = crc32_byte(ref_crc, frame_bytes[i]);

            $display("  Reference CRC          : 0x%08X", ref_crc);

            // Drive DUT word by word, sof on first, eof on last
            for (i = 0; i < FRAME_WORDS; i = i + 1) begin
                word = 0;
                for (b = 0; b < DATA_W/8; b = b + 1)
                    word = (word << 8) | frame_bytes[i*(DATA_W/8) + b];
                drive_word(word, (i == 0), (i == FRAME_WORDS-1));
            end

            wait_crc_valid(dut_crc, timed_out);

            if (!timed_out) begin
                if (dut_crc === ref_crc) begin
                    $display("  DUT result             : 0x%08X", dut_crc);
                    $display("  PASS");
                    pass_count = pass_count + 1;
                end else begin
                    $display("  DUT result             : 0x%08X  *** MISMATCH ***", dut_crc);
                    $display("  FAIL");
                    fail_count = fail_count + 1;
                end
            end else begin
                fail_count = fail_count + 1;
            end
        end
    endtask

    // =========================================================================
    // TEST 3 — Back-to-back frames (SOF reset check)
    //
    // Sends two identical frames with no idle between them.
    // SOF on the second frame must reset state_r to CRC_INIT so the second
    // CRC matches the first. If SOF is ignored, state bleeds between frames
    // and the second CRC will be wrong.
    // =========================================================================
    task test_back_to_back;
        integer          i, b;
        reg [7:0]        frame_bytes [0:FRAME_BYTES-1];
        reg [DATA_W-1:0] word;
        reg [31:0]       ref_crc;
        reg [31:0]       dut_crc_a, dut_crc_b;
        reg              timed_out;
        begin
            $display("----------------------------------------------------------");
            $display("TEST 3: Back-to-back frames (SOF reset check)");

            for (i = 0; i < FRAME_BYTES; i = i + 1)
                frame_bytes[i] = ((i * 53 + 7) ^ (i >> 2)) & 8'hFF;

            ref_crc = 32'hFFFFFFFF;
            for (i = 0; i < FRAME_BYTES; i = i + 1)
                ref_crc = crc32_byte(ref_crc, frame_bytes[i]);

            $display("  Reference CRC (both)   : 0x%08X", ref_crc);

            // Frame A
            for (i = 0; i < FRAME_WORDS; i = i + 1) begin
                word = 0;
                for (b = 0; b < DATA_W/8; b = b + 1)
                    word = (word << 8) | frame_bytes[i*(DATA_W/8) + b];
                drive_word(word, (i == 0), (i == FRAME_WORDS-1));
            end
            wait_crc_valid(dut_crc_a, timed_out);

            // Frame B — starts immediately on the next cycle, no idle
            for (i = 0; i < FRAME_WORDS; i = i + 1) begin
                word = 0;
                for (b = 0; b < DATA_W/8; b = b + 1)
                    word = (word << 8) | frame_bytes[i*(DATA_W/8) + b];
                drive_word(word, (i == 0), (i == FRAME_WORDS-1));
            end
            wait_crc_valid(dut_crc_b, timed_out);

            if (dut_crc_a === ref_crc && dut_crc_b === ref_crc) begin
                $display("  Frame A CRC            : 0x%08X", dut_crc_a);
                $display("  Frame B CRC            : 0x%08X", dut_crc_b);
                $display("  PASS — SOF correctly resets state between frames");
                pass_count = pass_count + 1;
            end else begin
                $display("  Frame A CRC  : 0x%08X %s", dut_crc_a,
                         (dut_crc_a !== ref_crc) ? "*** MISMATCH ***" : "OK");
                $display("  Frame B CRC  : 0x%08X %s", dut_crc_b,
                         (dut_crc_b !== ref_crc) ? "*** MISMATCH ***" : "OK");
                $display("  FAIL");
                fail_count = fail_count + 1;
            end
        end
    endtask

    // =========================================================================
    // TEST 4 — valid gap mid-frame (state hold check)
    //
    // Sends the first 100 words, idles for 5 cycles, then sends the rest.
    // state_r must not change during the gap (valid=0 blocks the register).
    // The final CRC must still match the reference computed on the full frame.
    // =========================================================================
    task test_valid_gap;
        integer          i, b;
        reg [7:0]        frame_bytes [0:FRAME_BYTES-1];
        reg [DATA_W-1:0] word;
        reg [31:0]       ref_crc;
        reg [31:0]       dut_crc;
        reg              timed_out;
        begin
            $display("----------------------------------------------------------");
            $display("TEST 4: valid gap mid-frame (state hold check)");

            for (i = 0; i < FRAME_BYTES; i = i + 1)
                frame_bytes[i] = ((i * 19 + 31) ^ (i >> 4)) & 8'hFF;

            ref_crc = 32'hFFFFFFFF;
            for (i = 0; i < FRAME_BYTES; i = i + 1)
                ref_crc = crc32_byte(ref_crc, frame_bytes[i]);

            $display("  Reference CRC          : 0x%08X", ref_crc);

            // Words 0..99
            for (i = 0; i < 100; i = i + 1) begin
                word = 0;
                for (b = 0; b < DATA_W/8; b = b + 1)
                    word = (word << 8) | frame_bytes[i*(DATA_W/8) + b];
                drive_word(word, (i == 0), 0);
            end

            // 5-cycle gap — valid pulled low
            idle_cycles(5);
            $display("  5-cycle valid gap applied after word 99");

            // Words 100..1336
            for (i = 100; i < FRAME_WORDS; i = i + 1) begin
                word = 0;
                for (b = 0; b < DATA_W/8; b = b + 1)
                    word = (word << 8) | frame_bytes[i*(DATA_W/8) + b];
                drive_word(word, 0, (i == FRAME_WORDS-1));
            end

            wait_crc_valid(dut_crc, timed_out);

            if (!timed_out) begin
                if (dut_crc === ref_crc) begin
                    $display("  DUT result             : 0x%08X", dut_crc);
                    $display("  PASS — state held correctly during valid gap");
                    pass_count = pass_count + 1;
                end else begin
                    $display("  DUT result             : 0x%08X  *** MISMATCH ***", dut_crc);
                    $display("  FAIL — state corrupted during valid gap");
                    fail_count = fail_count + 1;
                end
            end else begin
                fail_count = fail_count + 1;
            end
        end
    endtask

    // =========================================================================
    // TEST 5 — eof and valid asserted on the same cycle
    //
    // When eof and valid coincide, the DUT must use crc_next (which includes
    // that last word) rather than state_r (which does not yet include it).
    // Uses a short 4-word frame so the bug is easy to isolate if it exists.
    // =========================================================================
    task test_eof_valid_same_cycle;
        integer          i;
        reg [31:0]       ref_crc;
        reg [31:0]       dut_crc;
        reg              timed_out;
        reg [DATA_W-1:0] words [0:3];
        begin
            $display("----------------------------------------------------------");
            $display("TEST 5: eof + valid on same cycle (last word inclusion)");

            words[0] = 32'hDEADBEEF;
            words[1] = 32'hCAFEBABE;
            words[2] = 32'h01234567;
            words[3] = 32'h89ABCDEF;

            // Reference: 4 words = 16 bytes, MSB first
            ref_crc = 32'hFFFFFFFF;
            ref_crc = crc32_byte(ref_crc, 8'hDE); ref_crc = crc32_byte(ref_crc, 8'hAD);
            ref_crc = crc32_byte(ref_crc, 8'hBE); ref_crc = crc32_byte(ref_crc, 8'hEF);
            ref_crc = crc32_byte(ref_crc, 8'hCA); ref_crc = crc32_byte(ref_crc, 8'hFE);
            ref_crc = crc32_byte(ref_crc, 8'hBA); ref_crc = crc32_byte(ref_crc, 8'hBE);
            ref_crc = crc32_byte(ref_crc, 8'h01); ref_crc = crc32_byte(ref_crc, 8'h23);
            ref_crc = crc32_byte(ref_crc, 8'h45); ref_crc = crc32_byte(ref_crc, 8'h67);
            ref_crc = crc32_byte(ref_crc, 8'h89); ref_crc = crc32_byte(ref_crc, 8'hAB);
            ref_crc = crc32_byte(ref_crc, 8'hCD); ref_crc = crc32_byte(ref_crc, 8'hEF);

            $display("  Reference CRC          : 0x%08X", ref_crc);

            // Drive 4 words: eof asserts simultaneously with the last valid word
            for (i = 0; i < 4; i = i + 1)
                drive_word(words[i], (i == 0), (i == 3));

            wait_crc_valid(dut_crc, timed_out);

            if (!timed_out) begin
                if (dut_crc === ref_crc) begin
                    $display("  DUT result             : 0x%08X", dut_crc);
                    $display("  PASS — last word included via crc_next path");
                    pass_count = pass_count + 1;
                end else begin
                    $display("  DUT result             : 0x%08X  *** MISMATCH ***", dut_crc);
                    $display("  FAIL — last word likely missed (state_r used instead of crc_next)");
                    fail_count = fail_count + 1;
                end
            end else begin
                fail_count = fail_count + 1;
            end
        end
    endtask

    // =========================================================================
    // Main sequence
    // =========================================================================
    initial begin
        pass_count = 0;
        fail_count = 0;

        // Initialise all inputs
        rst_n   = 0;
        sof     = 0;
        valid   = 0;
        eof     = 0;
        data_in = 0;

        // Hold reset for 4 cycles then release
        repeat(4) @(posedge clk);
        rst_n = 1;
        repeat(2) @(posedge clk); #1;

        // Run tests with 4 idle cycles between each
        test_known_vector;         idle_cycles(4);
        test_full_frame;           idle_cycles(4);
        test_back_to_back;         idle_cycles(4);
        test_valid_gap;            idle_cycles(4);
        test_eof_valid_same_cycle; idle_cycles(4);

        // Final summary
        $display("==========================================================");
        $display("RESULTS:  %0d passed,  %0d failed", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("*** FAILURES DETECTED — review output above ***");
        $display("==========================================================");

        $finish;
    end

    // Global timeout — covers all 1337-cycle frames with margin
    initial begin
        #20000000;
        $display("GLOBAL TIMEOUT — simulation hung");
        $finish;
    end

endmodule

/*
Test 1 is a sanity check on the reference model itself — it confirms the polynomial 0x04C11DB7 and init value 0xFFFFFFFF are correct before trusting any DUT comparison. Since 9 bytes is not a multiple of 32 bits the DUT is not driven here, just the software model.
Test 2 is the main correctness test. It feeds all 1337 words of your 42784-bit frame and compares the DUT output against the byte-serial reference. If this passes, the parallel matrix is correct.
Test 3 catches state bleed between frames. It sends two identical frames back to back with no idle cycles between them and checks that both produce the same CRC. If the SOF mux is broken, the second frame inherits state from the first and its CRC will be wrong.
Test 4 checks that state_r holds correctly when valid drops mid-frame. It idles for 5 cycles after word 99 then resumes. A broken design might clear or corrupt state during the gap.
Test 5 isolates the eof + valid same-cycle path using a short 4-word frame. This directly tests the ternary valid ? crc_next : state_r in the always block — if state_r were used instead of crc_next on that cycle, the last word would be missing from the CRC and this test would catch it.
*/