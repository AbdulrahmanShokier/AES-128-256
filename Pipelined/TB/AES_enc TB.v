`timescale 1ns/1ps

module AES_enc_tb;

    // Parameters
    parameter BLOCK_LENGTH = 128;
    parameter CLK_PERIOD = 10;  // 10ns clock period (100MHz)
    parameter PIPELINE_STAGES = 11;  // Number of pipeline stages
    
    // Testbench signals
    reg                         clk;
    reg                         rst;
    reg      [BLOCK_LENGTH-1:0] IN;
    reg      [BLOCK_LENGTH-1:0] KEY;
    wire     [BLOCK_LENGTH-1:0] OUT;
    
    // Test vectors storage
    reg [BLOCK_LENGTH-1:0] expected_output;
    integer test_count;
    integer pass_count;
    integer fail_count;
    
    // DUT instantiation
    AES_enc #(
        .BLOCK_LENGTH(BLOCK_LENGTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .IN(IN),
        .KEY(KEY),
        .OUT(OUT)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test procedure
    initial begin
        // Initialize signals
        rst = 1;
        IN = 0;
        KEY = 0;
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        
        // Create VCD dump for waveform viewing
        $dumpfile("aes_enc_tb.vcd");
        $dumpvars(0, AES_enc_tb);
        
        // Display test start
        $display("========================================");
        $display("AES-128 Encryption Testbench Started");
        $display("========================================");
        
        // Apply reset
        #(CLK_PERIOD * 2);
        rst = 0;
        #(CLK_PERIOD * 2);
        rst = 1;
        #(CLK_PERIOD * 2);
        
        // Test Case 1: NIST FIPS-197 Standard Test Vector
        test_aes_vector(
            128'h00112233445566778899aabbccddeeff,  // Plaintext
            128'h000102030405060708090a0b0c0d0e0f,  // Key
            128'h69c4e0d86a7b0430d8cdb78070b4c55a   // Expected Ciphertext
        );
        
        // Test Case 2: All zeros
        test_aes_vector(
            128'h00000000000000000000000000000000,
            128'h00000000000000000000000000000000,
            128'h66e94bd4ef8a2c3b884cfa59ca342b2e
        );
        
        // Test Case 3: All ones
        test_aes_vector(
            128'hffffffffffffffffffffffffffffffff,
            128'hffffffffffffffffffffffffffffffff,
            128'hBCBF217CB280CF30B2517052193AB979
        );
        
        // Test Case 4: Another NIST test vector
        test_aes_vector(
            128'h00000000000000000000000000000000,
            128'h10a58869d74be5a374cf867cfb473859,
            128'h6d251e6944b051e04eaa6fb4dbf78465
        );
        
        // Test Case 5: Pattern test
        test_aes_vector(
            128'h0123456789abcdeffedcba9876543210,
            128'h0f1e2d3c4b5a69788796a5b4c3d2e1f0,
            128'h7BA5E93EA4B294F64F27DEBC819201C5								
        );
        
        // Test Case 6: Sequential pattern
        test_aes_vector(
            128'h00112233445566778899aabbccddeeff,
            128'h0f0e0d0c0b0a09080706050403020100,
            128'hF59D7CBF08FC47375511E6D9EECB6804								
        );
        
        // Wait for pipeline to flush
        #(CLK_PERIOD * PIPELINE_STAGES);
        
        // Display test results
        $display("\n========================================");
        $display("Test Summary:");
        $display("========================================");
        $display("Total Tests: %0d", test_count);
        $display("Passed:      %0d", pass_count);
        $display("Failed:      %0d", fail_count);
        $display("========================================\n");
        
        if (fail_count == 0)
            $display("*** ALL TESTS PASSED ***\n");
        else
            $display("*** SOME TESTS FAILED ***\n");
        
        // Finish simulation
        #(CLK_PERIOD * 10);
        $finish;
    end
    
    // Task to test AES encryption with a specific vector
    task test_aes_vector;
        input [BLOCK_LENGTH-1:0] plaintext;
        input [BLOCK_LENGTH-1:0] key;
        input [BLOCK_LENGTH-1:0] expected_cipher;
        begin
            test_count = test_count + 1;
            
            $display("\n----------------------------------------");
            $display("Test Case %0d:", test_count);
            $display("----------------------------------------");
            $display("Plaintext:  0x%032h", plaintext);
            $display("Key:        0x%032h", key);
            $display("Expected:   0x%032h", expected_cipher);
            
            // Apply inputs
            @(posedge clk);
            IN = plaintext;
            KEY = key;
            expected_output = expected_cipher;
            
            // Wait for pipeline delay
            repeat(PIPELINE_STAGES) @(posedge clk);
            
            // Check output
            @(posedge clk);
            #1; // Small delay for signal propagation
            
            $display("Got:        0x%032h", OUT);
            
            if (OUT === expected_cipher) begin
                $display("Status:     PASS ✓");
                pass_count = pass_count + 1;
            end else begin
                $display("Status:     FAIL ✗");
                $display("Mismatch detected!");
                fail_count = fail_count + 1;
            end
        end
    endtask
    
    // Monitor for continuous output observation (optional)
    initial begin
        $display("\nTime\t\tInput\t\t\t\tKey\t\t\t\tOutput");
        $display("----\t\t-----\t\t\t\t---\t\t\t\t------");
        $monitor("%0t\t%h\t%h\t%h", $time, IN, KEY, OUT);
    end
    
    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * 1000);
        $display("\n*** ERROR: Simulation timeout! ***");
        $finish;
    end

endmodule



/*
working
*/