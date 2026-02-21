`timescale 1ns/1ps

module tb_AES_hardware_test_top;

    // Inputs
    reg clk;
    reg rst;

    // Outputs
    wire led_success;
    wire led_error;
    wire led_done;

    // -------------------------------------------------
    // Instantiate the Unit Under Test (UUT)
    // -------------------------------------------------
    AES_hardware_test_top dut (
        .clk(clk), 
        .rst(rst), 
        .led_success(led_success), 
        .led_error(led_error), 
        .led_done(led_done)
    );

    // -------------------------------------------------
    // Clock Generation (100 MHz to match Atlys board)
    // -------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period (100 MHz)
    end

    // -------------------------------------------------
    // Test Sequence
    // -------------------------------------------------
    initial begin
        // 1. Start with the system in reset (Switch DOWN)
        rst = 0; 
        $display("Time: %0t | System in Reset...", $time);

        // Wait a bit
        #100;
        
        // 2. Release reset to start the FSM (Switch UP)
        rst = 1;
        $display("Time: %0t | Reset released. FSM starting...", $time);

        // 3. Wait for the 'done' LED to turn on
        // The wait() statement pauses the simulation until the condition is true
        wait(led_done == 1'b1);
        
        // Wait a few more clock cycles just to let everything settle
        #50;
        
        // 4. Print the final LED status
        $display("\n========================================");
        $display("Hardware Test Simulation Finished!");
        $display("LED Status:");
        $display("  led_done    (LED 2) = %b", led_done);
        $display("  led_error   (LED 1) = %b", led_error);
        $display("  led_success (LED 0) = %b", led_success);
        
        if (led_success && !led_error) begin
            $display("\nRESULT: PASS! All 11 vectors encrypted and decrypted flawlessly.");
        end else begin
            $display("\nRESULT: FAIL! A mismatch occurred during the loopback.");
        end
        $display("========================================\n");

        $finish;
    end
    
    // -------------------------------------------------
    // Error Monitor (Optional)
    // -------------------------------------------------
    // If the error LED lights up early, print a message right away
    always @(posedge clk) begin
        if (led_error && !led_done) begin
            $display("Time: %0t | WARNING: Error LED triggered mid-test!", $time);
        end
    end

endmodule