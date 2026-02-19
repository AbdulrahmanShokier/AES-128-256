`timescale 1ns/1ps

module tb_AES_dec_full_pipeline_in;

    reg clk;
    reg rst;

    reg  [127:0] IN;
    reg  [127:0] KEY;
//    reg          enable;
    reg          fsm_en;

    wire [127:0] OUT;
    // -------------------------------------------------
    // DUT
    // -------------------------------------------------
    AES_dec dut (
        .clk(clk),
        .rst(rst),
        .IN(IN),
        .KEY(KEY),
//        .enable(enable),
        .fsm_en(fsm_en),
        .OUT(OUT)
    );
    // -------------------------------------------------
    // Clock
    // -------------------------------------------------
    initial begin
        clk = 0;
        forever #10 clk = ~clk; // changed to #10 for slower clock
    end

    // -------------------------------------------------
    // Stimulus
    // -------------------------------------------------
    initial begin
        rst = 0;
//        enable = 0;
        fsm_en = 0;
        IN = 0;

        KEY = 128'h000102030405060708090A0B0C0D0E0F;
        // Reset
        #100; // increased to #100 for Xilinx Global Reset 
        rst = 1;
        // Trigger FSM (single pulse)
        @(posedge clk);
        #1 fsm_en = 1; // Added #1 delay

        @(posedge clk);
        #1 fsm_en = 0; // Added #1 delay

        @(posedge clk);
           // NOP to wait for the key generator to calculate the 10 keys #1

        @(posedge clk);
        // NOP to wait for the key generator to calculate the 10 keys #2

        @(posedge clk);
        // NOP to wait for the key generator to calculate the 10 keys #3

        @(posedge clk);
        // NOP to wait for the key generator to calculate the 10 keys #4

        @(posedge clk);
        // NOP to wait for the key generator to calculate the 10 keys #5

        @(posedge clk);
        // NOP to wait for the key generator to calculate the 10 keys #6

        @(posedge clk);
        // NOP to wait for the key generator to calculate the 10 keys #7

        @(posedge clk);
        // NOP to wait for the key generator to calculate the 10 keys #8

        @(posedge clk);
        // NOP to wait for the key generator to calculate the 10 keys #9

        @(posedge clk);
        // NOP to wait for the key generator to calculate the 10 keys #10

        @(posedge clk);
        // NOP to wait for the key generator to calculate the 10 keys #10

        // -----------------------------------------
        //  Fill pipeline with 11 inputs (Round 0 → 10)
        //  Each one enters in a separate clock cycle
        // -----------------------------------------

        // ----- INPUT 0 -----
        @(posedge clk);
        #1 IN = 128'h69C4E0D86A7B0430D8CDB78070B4C55A;   // Added #1 delay
   //     enable = 1;
        //00112233445566778899AABBCCDDEEFF

        // ----- INPUT 1 -----
        @(posedge clk);
        #1 IN = 128'h818E5127D2F7B75A1380BF3C70DF47ED;   // Added #1 delay
    //    enable = 1;
        //00112233445566000099AABBCCDDEEFF


        // ----- INPUT 2 -----
        @(posedge clk);
        #1 IN = 128'hBEB0796011FC79B11F2708F8EC037700;   // Added #1 delay
   //     enable = 1;
        //66542233445566000099AABBCCDDEEFF

        // ----- INPUT 3 -----
        @(posedge clk);
        #1 IN = 128'hC6A13B37878F5B826F4F8162A1C8D879;   // Added #1 delay
    //    enable = 1;
        //00000000000000000000000000000000


        // ----- INPUT 4 -----
        @(posedge clk);
        #1 IN = 128'h35D14E6D3E3A279CF01E343E34E7DED3;   // Added #1 delay
    //    enable = 1;
        //11111111111111111111111111111111

        // ----- INPUT 5 -----
        @(posedge clk);
        #1 IN = 128'h954F64F2E4E86E9EEE82D20216684899;   // Added #1 delay
    //    enable = 1;
        //10101010101010101010101010101010


        // ----- INPUT 6 -----
        @(posedge clk);
        #1 IN = 128'hC352805754237F311AC0FFF4E3E03E78;   // Added #1 delay
    //    enable = 1;
        //    //01010101010101010101010101010101


        // ----- INPUT 7 -----
        @(posedge clk);
        #1 IN = 128'hEA5E61AE8167CAA0586388EB9A7CB755;   // Added #1 delay
    //    enable = 1;
        //05050505050505050505050505050505


        // ----- INPUT 8 -----
        @(posedge clk);
        #1 IN = 128'h3C441F32CE07822364D7A2990E50BB13;   // Added #1 delay
     //   enable = 1;
        //ffffffffffffffffffffffffffffffff


        // ----- INPUT 9 -----
        @(posedge clk);
        #1 IN = 128'hAA7F07422BD898330D8BDB89D3099CDE;   // Added #1 delay
     //   enable = 1;
        //33333333333333333333333333333333


        // ----- INPUT 10 -----
        @(posedge clk);
        #1 IN = 128'hAEB05C6BB162066E45E078946DB82C7F;   // Added #1 delay
    //    enable = 1;
        //cccccccccccccccccccccccccccccccc


        // Done sending — turn enable off
        @(posedge clk);
//        enable = 0;
        #1 IN = 0; // Added #1 delay

        // Wait for pipeline to flush
        repeat(40) @(posedge clk);
        $finish;
    end

    

endmodule