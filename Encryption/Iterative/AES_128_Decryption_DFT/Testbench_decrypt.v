`timescale 1ns / 1ps

/*
 * Testbench for the "single-shot" AES_DFT_Decrypt module.
 *
 * This testbench verifies the AES Decryption core on the FPGA.
 * It follows the same logic as the encryption test:
 * 1. Loop from i = 0 to 7 (selecting test vectors via 'sw').
 * 2. Set the 'sw' inputs to 'i'.
 * 3. Pulse the 'rst_n' (reset) button to trigger the FSM in AES_DFT_Decrypt.
 * 4. Wait for 'led_success' (Green) or 'led_fail' (Red) to go high.
 * 5. Check the result and report Pass/Fail.
 * 6. Repeat for the next 'i'.
 */
module tb_AES_DFT_Decrypt_Reset_Method;

    // Parameters
    parameter CLK_PERIOD = 10; // 10ns = 100MHz (matches Atlys clock)

    // Inputs to the DUT (AES_DFT_Decrypt) are 'reg'
    reg clk;
    reg rst_n;
    reg [2:0] sw;

    // Outputs from the DUT (AES_DFT_Decrypt) are 'wire'
    wire led_success;
    wire led_fail;
    
    // Test tracking
    integer i;
    integer error_count;

    //----------------------------------------------------------------------
    // Instantiate the Device Under Test (DUT)
    // This must be your AES_DFT_Decrypt module
    //----------------------------------------------------------------------
    AES_DFT_Decrypt DUT (
        .clk(clk),
        .rst_n(rst_n),
        .sw(sw),
        .led_success(led_success),
        .led_fail(led_fail)
    );

    //----------------------------------------------------------------------
    // Clock Generation
    //----------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    //----------------------------------------------------------------------
    // Test Procedure
    //----------------------------------------------------------------------
    initial begin
        $display("SIMULATION START: Testing all 8 switch combinations for DECRYPTION.");
        error_count = 0;

        // Initialize signals
        rst_n = 1'b1; // Start with reset released (active-low)
        sw = 3'b000;
        #(CLK_PERIOD * 10);

        // Loop through all 8 test cases
        for (i = 0; i < 8; i = i + 1) begin
            $display("--- Setting switches for DECRYPTION TEST CASE %d ---", i);
            sw = i; // 1. Set the switches
            
            #(CLK_PERIOD * 10); // Wait for switches to "settle"

            // 2. Apply Reset Pulse to start the test
            // (The FSM in AES_DFT_Decrypt waits for reset to be released to start)
            $display("Pulsing reset to start decryption test...");
            rst_n = 1'b0; // Press reset (active-low)
            #(CLK_PERIOD * 5); // Hold reset for 5 cycles
            rst_n = 1'b1; // Release reset
            
            // 3. Wait for the DUT to finish
            // The FSM will run and latch an LED high in STATE_DONE_LATCH
            // We add a timeout just in case something is broken
            fork : wait_for_leds
                begin
                    wait (led_success == 1'b1 || led_fail == 1'b1);
                end
                begin
                    #(CLK_PERIOD * 200); // Timeout after 200 cycles (adjust if decryption is very slow)
                    disable wait_for_leds; // Stop waiting if timeout occurs
                end
            join

            #(CLK_PERIOD); // Wait 1 cycle to read the latched value

            // 4. Check the result
            if (led_success == 1'b1) begin
                 $display("Test Case %d PASSED.", i);
            end else if (led_fail == 1'b1) begin
                $display(">>> TEST CASE %d FAILED! 'led_fail' is high.", i);
                error_count = error_count + 1;
            end else begin
                 $display(">>> TEST CASE %d TIMEOUT! No LED lit.", i);
                 error_count = error_count + 1;
            end
            
            #(CLK_PERIOD * 20); // Wait before next test
        end

        // 5. Final Report
        #(CLK_PERIOD * 20);
        if (error_count == 0) begin
            $display("\n*** ALL 8 DECRYPTION TESTS PASSED! ***");
        end else begin
            $display("\n*** SIMULATION FAILED. %d of 8 tests failed. ***", error_count);
        end

       
    end

endmodule