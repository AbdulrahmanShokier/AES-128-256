`timescale 1ns/1ps

module AES_enc TB full pipeline_with_enable;

    // Parameters
    parameter BLOCK_LENGTH = 128;
    parameter CLK_PERIOD = 10;        // 10ns = 100MHz
    parameter PIPELINE_DEPTH = 11;    // Matches your pipeline stages (r0-r10)
    
    // Signals
    reg                         clk;
    reg                         rst;
    reg                         enable;
    reg      [BLOCK_LENGTH-1:0] IN;
    reg      [BLOCK_LENGTH-1:0] KEY;
    wire     [BLOCK_LENGTH-1:0] OUT;
    
    // Test data arrays - store 11 test vectors
    reg [BLOCK_LENGTH-1:0] plaintext_array [0:PIPELINE_DEPTH-1];
    reg [BLOCK_LENGTH-1:0] key_array [0:PIPELINE_DEPTH-1];
    reg [BLOCK_LENGTH-1:0] expected_array [0:PIPELINE_DEPTH-1];
    
    // Counters
    integer input_counter;
    integer output_counter;
    integer pass_count;
    integer fail_count;
    integer clock_cycle;
    
    // DUT instantiation
    AES_enc #(
        .BLOCK_LENGTH(BLOCK_LENGTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .IN(IN),
        .KEY(KEY),
        .OUT(OUT),
        .enable(enable)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Clock cycle counter
    always @(posedge clk) begin
        if (!rst)
            clock_cycle <= 0;
        else
            clock_cycle <= clock_cycle + 1;
    end
    
    // Main test sequence
    initial begin
        // Initialize
        rst = 0;
        IN = 0;
        KEY = 0;
        enable=1;
        input_counter = 0;
        output_counter = 0;
        pass_count = 0;
        fail_count = 0;
        clock_cycle = 0;
        
        // Setup waveform dump
        $dumpfile("aes_pipeline_fill.vcd");
        $dumpvars(0, AES_enc_fill_pipeline_tb);
        
        // Display header
        $display("\n================================================================");
        $display("AES-128 Pipeline Fill Test");
        $display("================================================================");
        $display("Pipeline Depth:  %0d stages", PIPELINE_DEPTH);
        $display("Test Strategy:   Feed %0d inputs continuously (1 per clock)", PIPELINE_DEPTH);
        $display("Expected Result: Pipeline fully occupied, then %0d outputs", PIPELINE_DEPTH);
        $display("================================================================\n");
        
        // Initialize test vectors
        initialize_test_data();
        
        // Apply reset
        $display("[INFO] Applying reset...");
        #(CLK_PERIOD * 2);
        rst = 1;
        #(CLK_PERIOD);
        
        $display("[INFO] Reset released. Starting pipeline fill...\n");
        
        // Feed the pipeline - 11 inputs, one per clock cycle
        fork
            // Process 1: Feed inputs
            begin
                for (input_counter = 0; input_counter < PIPELINE_DEPTH; input_counter = input_counter + 1) begin
                    @(posedge clk);
                    #1; // Small delta delay
                    IN = plaintext_array[input_counter];
                    KEY = key_array[input_counter];
                    
                    $display("[Cycle %2d] INPUT  #%2d: PT=0x%032h, KEY=0x%08h...%08h", 
                             clock_cycle, input_counter, 
                             plaintext_array[input_counter],
                             key_array[input_counter][127:96],
                             key_array[input_counter][31:0]);
                end
                
                $display("\n[Cycle %2d] *** All %0d inputs fed - Pipeline is FULL ***\n", 
                         clock_cycle, PIPELINE_DEPTH);
                
                // Stop feeding, but keep last input stable
                @(posedge clk);
                #1;
                IN = 0;
                KEY = 0;
            end
            
            // Process 2: Check outputs (starts after pipeline delay)
            begin
                // Wait for pipeline to fill
                repeat(PIPELINE_DEPTH) @(posedge clk);
                
                $display("[Cycle %2d] First output should appear now...\n", clock_cycle);
                
                // Check all 11 outputs
                for (output_counter = 0; output_counter < PIPELINE_DEPTH; output_counter = output_counter + 1) begin
                    @(posedge clk);
                    #1; // Wait for output to settle
                    
                    $display("[Cycle %2d] OUTPUT #%2d: CT=0x%032h", 
                             clock_cycle, output_counter, OUT);
                    
                    // Verify output
                    if (OUT === expected_array[output_counter]) begin
                        $display("                  Status: PASS ✓");
                        pass_count = pass_count + 1;
                    end else begin
                        $display("                  Status: FAIL ✗");
                        $display("                  Expected: 0x%032h", expected_array[output_counter]);
                        $display("                  Got:      0x%032h", OUT);
                        fail_count = fail_count + 1;
                    end
                    $display("");
                end
                
                $display("[Cycle %2d] *** All %0d outputs received - Pipeline is EMPTY ***\n", 
                         clock_cycle, PIPELINE_DEPTH);
            end
        join
        
        // Display results
        display_summary();
        
        // End simulation
        #(CLK_PERIOD * 5);
        $finish;
    end
    
    // Initialize test data with known AES test vectors
    task initialize_test_data;
        begin
            $display("[INFO] Initializing %0d test vectors...\n", PIPELINE_DEPTH);
            
            // Test Vector 0: NIST FIPS-197 Appendix C.1
            plaintext_array[0] = 128'h00112233445566778899aabbccddeeff;
            key_array[0]       = 128'h000102030405060708090a0b0c0d0e0f;
            expected_array[0]  = 128'h69c4e0d86a7b0430d8cdb78070b4c55a;
            
            // Test Vector 1: All zeros
            plaintext_array[1] = 128'h00000000000000000000000000000000;
            key_array[1]       = 128'h00000000000000000000000000000000;
            expected_array[1]  = 128'h66e94bd4ef8a2c3b884cfa59ca342b2e;
            
            // Test Vector 2: All ones
            plaintext_array[2] = 128'hffffffffffffffffffffffffffffffff;
            key_array[2]       = 128'hffffffffffffffffffffffffffffffff;
            expected_array[2]  = 128'hBCBF217CB280CF30B2517052193AB979;
            
            // Test Vector 3: NIST test
            plaintext_array[3] = 128'h00000000000000000000000000000000;
            key_array[3]       = 128'h10a58869d74be5a374cf867cfb473859;
            expected_array[3]  = 128'h6d251e6944b051e04eaa6fb4dbf78465;
            
            // Test Vector 4: Pattern
            plaintext_array[4] = 128'h0123456789abcdeffedcba9876543210;
            key_array[4]       = 128'h0f1e2d3c4b5a69788796a5b4c3d2e1f0;
            expected_array[4]  = 128'h7BA5E93EA4B294F64F27DEBC819201C5;
            
            // Test Vector 5: Alternating bits
            plaintext_array[5] = 128'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
            key_array[5]       = 128'h55555555555555555555555555555555;
            expected_array[5]  = 128'h4E194AC3FB1DA6291F5EBAB5743E96D4; // Replace with actual value
            
            // Test Vector 6: Sequential
            plaintext_array[6] = 128'h00112233445566778899aabbccddeeff;
            key_array[6]       = 128'h0f0e0d0c0b0a09080706050403020100;
            expected_array[6]  = 128'hF59D7CBF08FC47375511E6D9EECB6804;
            
            // Test Vector 7: Inverse pattern
            plaintext_array[7] = 128'hffeeddccbbaa99887766554433221100;
            key_array[7]       = 128'h00112233445566778899aabbccddeeff; 
            expected_array[7]  = 128'h7221393918A24D7D0EE3F2223BFA5B35;
            
            // Test Vector 8: High entropy
            plaintext_array[8] = 128'h6bc1bee22e409f96e93d7e117393172a;
            key_array[8]       = 128'h2b7e151628aed2a6abf7158809cf4f3c;
            expected_array[8]  = 128'h3AD77BB40D7A3660A89ECAF32466EF97;
            
            // Test Vector 9: Random pattern 1
            plaintext_array[9] = 128'ha12c3f4a678492103e9f7e71b441635a;
            key_array[9]       = 128'he27e15962843d2a6ccf715e309cf4f57;
            expected_array[9]  = 128'hDBF681DA82CB4F2205B36AB77AA20761;
            
            // Test Vector 10: Random pattern 2
            plaintext_array[10] = 128'ha17e3f4a6784922f3e743c71b4419185;
            key_array[10]       = 128'he27e71562882d22bccf7154c8a7b4f7f;
            expected_array[10]  = 128'hF417F87D8E97171A88B963654781E1B8;
            
            $display("[INFO] Test vectors initialized.\n");
        end
    endtask
    
    // Display test summary
    task display_summary;
        real throughput_gbps;
        integer total_cycles;
        begin
            total_cycles = clock_cycle;
            throughput_gbps = (BLOCK_LENGTH * 1.0) / CLK_PERIOD;
            
            $display("================================================================");
            $display("TEST SUMMARY");
            $display("================================================================");
            $display("Total Inputs Fed:        %0d", PIPELINE_DEPTH);
            $display("Total Outputs Received:  %0d", PIPELINE_DEPTH);
            $display("----------------------------------------------------------------");
            $display("PASSED:                  %0d", pass_count);
            $display("FAILED:                  %0d", fail_count);
            $display("----------------------------------------------------------------");
            $display("Pipeline Statistics:");
            $display("  Input Phase:           Cycles 1-%0d (feeding)", PIPELINE_DEPTH);
            $display("  Pipeline Full:         Cycle %0d", PIPELINE_DEPTH);
            $display("  Output Phase:          Cycles %0d-%0d (draining)", 
                     PIPELINE_DEPTH + 1, PIPELINE_DEPTH * 2);
            $display("  Total Duration:        %0d cycles", total_cycles);
            $display("----------------------------------------------------------------");
            $display("Performance:");
            $display("  Throughput:            %.2f Gbps @ 100MHz", throughput_gbps);
            $display("  Latency:               %0d cycles", PIPELINE_DEPTH);
            $display("  Max Throughput:        1 block/cycle (when full)");
            $display("================================================================");
            
            if (fail_count == 0) begin
                $display("\n*** ALL TESTS PASSED ✓ ***");
                $display("Pipeline successfully filled and drained!\n");
            end else begin
                $display("\n*** %0d TEST(S) FAILED ✗ ***", fail_count);
                $display("Check expected values and implementation.\n");
            end
            
            $display("================================================================\n");
        end
    endtask
    
    // Optional: Monitor for debugging
    initial begin
        $display("\nPipeline Stage Monitoring:");
        $display("Time(ns) | Cycle | Stage | Activity");
        $display("---------|-------|-------|----------------------------------");
    end
    
    always @(posedge clk) begin
        if (rst && clock_cycle <= PIPELINE_DEPTH * 2 + 2) begin
            if (input_counter > 0 && input_counter <= PIPELINE_DEPTH) begin
                $display("%8t | %5d | INPUT | Feeding vector #%0d", 
                         $time, clock_cycle, input_counter - 1);
            end
            if (clock_cycle >= PIPELINE_DEPTH && clock_cycle < PIPELINE_DEPTH * 2) begin
                $display("%8t | %5d | OUTPT | Receiving vector #%0d", 
                         $time, clock_cycle, clock_cycle - PIPELINE_DEPTH);
            end
        end
    end
    
    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * 100);
        $display("\n*** TIMEOUT ERROR ***");
        $display("Simulation ran too long. Check for stalls or hangs.\n");
        $finish;
    end

endmodule



/*
================================================================
AES-128 Pipeline Fill Test
================================================================
Pipeline Depth:  11 stages
Test Strategy:   Feed 11 inputs continuously (1 per clock)
Expected Result: Pipeline fully occupied, then 11 outputs
================================================================

[Cycle  1] INPUT  #0: PT=0x00112233...
[Cycle  2] INPUT  #1: PT=0x00000000...
...
[Cycle 11] INPUT  #10: PT=0xdeadbeef...

[Cycle 11] *** All 11 inputs fed - Pipeline is FULL ***

[Cycle 12] OUTPUT #0: CT=0x69c4e0d8...
           Status: PASS ✓

[Cycle 13] OUTPUT #1: CT=0x66e94bd4...
           Status: PASS ✓
*/