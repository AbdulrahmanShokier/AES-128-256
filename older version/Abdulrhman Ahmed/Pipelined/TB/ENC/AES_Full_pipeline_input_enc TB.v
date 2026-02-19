`timescale 1ns/1ps

module tb_AES_enc;

    reg clk;
    reg rst;

    reg  [127:0] IN;
    reg  [127:0] KEY;
    reg          enable;   // Now active
    reg          fsm_en;

    wire [127:0] OUT;
    wire         valid_out; // To track when output is valid

    // -------------------------------------------------
    // DUT (Device Under Test)
    // -------------------------------------------------
    AES_enc dut (
        .clk(clk),
        .rst(rst),
        .IN(IN),
        .KEY(KEY),
        .enable(enable),      // Connected to drive validity
        .fsm_en(fsm_en),
        .OUT(OUT),
        .valid_out(valid_out) // Connected to monitor validity
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
            $display("Time: %t | Valid Encrypted Output: %h", $time, OUT);
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
        #1 IN = 128'h00112233445566778899AABBCCDDEEFF;
           enable = 1;
        // Expected: 69C4E0D86A7B0430D8CDB78070B4C55A

        // ----- INPUT 1 -----
        @(posedge clk);
        #1 IN = 128'h00112233445566000099AABBCCDDEEFF;
           enable = 1;
        // Expected: 818E5127D2F7B75A1380BF3C70DF47ED

        // ----- INPUT 2 -----
        @(posedge clk);
        #1 IN = 128'h66542233445566000099AABBCCDDEEFF;
           enable = 1;
        // Expected: BEB0796011FC79B11F2708F8EC037700

        // ----- INPUT 3 -----
        @(posedge clk);
        #1 IN = 128'h00000000000000000000000000000000;
           enable = 1;
        // Expected: C6A13B37878F5B826F4F8162A1C8D879

        // ----- INPUT 4 -----
        @(posedge clk);
        #1 IN = 128'h11111111111111111111111111111111;
           enable = 1;
        // Expected: 35D14E6D3E3A279CF01E343E34E7DED3

        // ----- INPUT 5 -----
        @(posedge clk);
        #1 IN = 128'h10101010101010101010101010101010;
           enable = 1;
        // Expected: 954F64F2E4E86E9EEE82D20216684899

        // ----- INPUT 6 -----
        @(posedge clk);
        #1 IN = 128'h01010101010101010101010101010101;
           enable = 1;
        // Expected: C352805754237F311AC0FFF4E3E03E78

        // ----- INPUT 7 -----
        @(posedge clk);
        #1 IN = 128'h05050505050505050505050505050505;
           enable = 1;
        // Expected: EA5E61AE8167CAA0586388EB9A7CB755

        // ----- INPUT 8 -----
        @(posedge clk);
        #1 IN = 128'hffffffffffffffffffffffffffffffff;
           enable = 1;
        // Expected: 3C441F32CE07822364D7A2990E50BB13

        // ----- INPUT 9 -----
        @(posedge clk);
        #1 IN = 128'h33333333333333333333333333333333;
           enable = 1;
        // Expected: AA7F07422BD898330D8BDB89D3099CDE

        // ----- INPUT 10 -----
        @(posedge clk);
        #1 IN = 128'hcccccccccccccccccccccccccccccccc;
           enable = 1;
        // Expected: AEB05C6BB162066E45E078946DB82C7F

        // Done sending — turn enable off to stop validity
        @(posedge clk);
        #1 IN = 0;
           enable = 0; 

        // Wait for pipeline to flush
        repeat(20) @(posedge clk);
        
        $finish;
    end

endmodule