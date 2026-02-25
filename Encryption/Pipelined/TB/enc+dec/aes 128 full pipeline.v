`timescale 1ns/1ps

module tb_AES_cascade_top;

    reg clk;
    reg rst;

    reg  [127:0] plaintext_in;
    reg  [127:0] key;
    reg          enable;
    reg          fsm_en;

    wire [127:0] plaintext_out;
    wire         valid_out;

    // -------------------------------------------------
    // DUT (Device Under Test)
    // -------------------------------------------------
    AES_cascade_top dut (
        .clk(clk),
        .rst(rst),
        .plaintext_in(plaintext_in),
        .key(key),
        .enable(enable),      
        .fsm_en(fsm_en),
        .plaintext_out(plaintext_out),
        .valid_out(valid_out) 
    );

    // -------------------------------------------------
    // Clock Generation
    // -------------------------------------------------
    initial begin
        clk = 0;
        forever #10 clk = ~clk; // 20ns period (50MHz)
    end

    // -------------------------------------------------
    // Output Monitor
    // -------------------------------------------------
    // This block prints the output ONLY when valid_out is high
    always @(posedge clk) begin
        if (valid_out) begin
            // The output here should exactly match the input vectors you sent
            $display("Time: %t | Valid Decrypted Output: %h", $time, plaintext_out);
        end
    end

    // -------------------------------------------------
    // Stimulus
    // -------------------------------------------------
    initial begin
        // Init signals
        rst = 0;
        enable = 0;
        fsm_en = 0;
        plaintext_in = 0;
        key = 128'h000102030405060708090A0B0C0D0E0F;

        // Reset
        #100;
        rst = 1;

        // Trigger Key Expansion FSM (single pulse)
        @(posedge clk);
        #1 fsm_en = 1;
        @(posedge clk);
        #1 fsm_en = 0;

        // Wait for Key Expansion (11 cycles)
        repeat(11) @(posedge clk);

        // -----------------------------------------
        //  Fill pipeline with 11 inputs
        //  We set 'enable = 1' to mark these as valid data
        // -----------------------------------------

        // ----- INPUT 0 -----
        @(posedge clk);
        #1 plaintext_in = 128'h00112233445566778899AABBCCDDEEFF;
           enable = 1;

        // ----- INPUT 1 -----
        @(posedge clk);
        #1 plaintext_in = 128'h00112233445566000099AABBCCDDEEFF;
           enable = 1;

        // ----- INPUT 2 -----
        @(posedge clk);
        #1 plaintext_in = 128'h66542233445566000099AABBCCDDEEFF;
           enable = 1;

        // ----- INPUT 3 -----
        @(posedge clk);
        #1 plaintext_in = 128'h00000000000000000000000000000000;
           enable = 1;

        // ----- INPUT 4 -----
        @(posedge clk);
        #1 plaintext_in = 128'h11111111111111111111111111111111;
           enable = 1;

        // ----- INPUT 5 -----
        @(posedge clk);
        #1 plaintext_in = 128'h10101010101010101010101010101010;
           enable = 1;

        // ----- INPUT 6 -----
        @(posedge clk);
        #1 plaintext_in = 128'h01010101010101010101010101010101;
           enable = 1;

        // ----- INPUT 7 -----
        @(posedge clk);
        #1 plaintext_in = 128'h05050505050505050505050505050505;
           enable = 1;

        // ----- INPUT 8 -----
        @(posedge clk);
        #1 plaintext_in = 128'hffffffffffffffffffffffffffffffff;
           enable = 1;

        // ----- INPUT 9 -----
        @(posedge clk);
        #1 plaintext_in = 128'h33333333333333333333333333333333;
           enable = 1;

        // ----- INPUT 10 -----
        @(posedge clk);
        #1 plaintext_in = 128'hcccccccccccccccccccccccccccccccc;
           enable = 1;

        // Done sending — turn enable off to stop validity
        @(posedge clk);
        #1 plaintext_in = 0;
           enable = 0; 

        // Wait for pipeline to flush (Increased to 40 for double pipeline)
        repeat(40) @(posedge clk); 
        $finish;
    end

endmodule