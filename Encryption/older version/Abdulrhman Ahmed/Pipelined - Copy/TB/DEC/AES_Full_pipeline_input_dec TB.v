`timescale 1ns/1ps

module tb_AES_dec;

    reg clk;
    reg rst;

    reg  [127:0] IN;
    reg  [127:0] KEY;
    reg          enable;    // Now active
    reg          fsm_en;

    wire [127:0] OUT;
    wire         valid_out; // To track when output is valid

    // -------------------------------------------------
    // DUT (Device Under Test)
    // -------------------------------------------------
    AES_dec dut (
        .clk(clk),
        .rst(rst),
        .IN(IN),
        .KEY(KEY),
        .enable(enable),       // Connected to drive validity
        .fsm_en(fsm_en),
        .OUT(OUT),
        .valid_out(valid_out)  // Connected to monitor validity
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
            $display("Time: %t | Valid Decrypted Output: %h", $time, OUT);
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
        IN = 0;
        KEY = 128'h000102030405060708090A0B0C0D0E0F;

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
        #1 IN = 128'h69C4E0D86A7B0430D8CDB78070B4C55A;
           enable = 1;
        // Expected Plaintext: 00112233445566778899AABBCCDDEEFF

        // ----- INPUT 1 -----
        @(posedge clk);
        #1 IN = 128'h818E5127D2F7B75A1380BF3C70DF47ED;
           enable = 1;
        // Expected Plaintext: 00112233445566000099AABBCCDDEEFF

        // ----- INPUT 2 -----
        @(posedge clk);
        #1 IN = 128'hBEB0796011FC79B11F2708F8EC037700;
           enable = 1;
        // Expected Plaintext: 66542233445566000099AABBCCDDEEFF

        // ----- INPUT 3 -----
        @(posedge clk);
        #1 IN = 128'hC6A13B37878F5B826F4F8162A1C8D879;
           enable = 1;
        // Expected Plaintext: 00000000000000000000000000000000

        // ----- INPUT 4 -----
        @(posedge clk);
        #1 IN = 128'h35D14E6D3E3A279CF01E343E34E7DED3;
           enable = 1;
        // Expected Plaintext: 11111111111111111111111111111111

        // ----- INPUT 5 -----
        @(posedge clk);
        #1 IN = 128'h954F64F2E4E86E9EEE82D20216684899;
           enable = 1;
        // Expected Plaintext: 10101010101010101010101010101010

        // ----- INPUT 6 -----
        @(posedge clk);
        #1 IN = 128'hC352805754237F311AC0FFF4E3E03E78;
           enable = 1;
        // Expected Plaintext: 01010101010101010101010101010101

        // ----- INPUT 7 -----
        @(posedge clk);
        #1 IN = 128'hEA5E61AE8167CAA0586388EB9A7CB755;
           enable = 1;
        // Expected Plaintext: 05050505050505050505050505050505

        // ----- INPUT 8 -----
        @(posedge clk);
        #1 IN = 128'h3C441F32CE07822364D7A2990E50BB13;
           enable = 1;
        // Expected Plaintext: ffffffffffffffffffffffffffffffff

        // ----- INPUT 9 -----
        @(posedge clk);
        #1 IN = 128'hAA7F07422BD898330D8BDB89D3099CDE;
           enable = 1;
        // Expected Plaintext: 33333333333333333333333333333333

        // ----- INPUT 10 -----
        @(posedge clk);
        #1 IN = 128'hAEB05C6BB162066E45E078946DB82C7F;
           enable = 1;
        // Expected Plaintext: cccccccccccccccccccccccccccccccc

        // Done sending — turn enable off to stop validity
        @(posedge clk);
        #1 IN = 0;
           enable = 0; 

        // Wait for pipeline to flush
        repeat(20) @(posedge clk);
        
        $finish;
    end

endmodule