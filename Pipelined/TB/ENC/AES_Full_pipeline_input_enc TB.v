`timescale 1ns/1ps

module tb_AES_enc_full_pipeline_in;

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
    AES_enc dut (
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
        forever #5 clk = ~clk;
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
        #20;
        rst = 1;

        // Trigger FSM (single pulse)
        @(posedge clk);
        fsm_en = 1;

        @(posedge clk);
        fsm_en = 0;

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

        // -----------------------------------------
        //  Fill pipeline with 11 inputs (Round 0 → 10)
        //  Each one enters in a separate clock cycle
        // -----------------------------------------

        // ----- INPUT 0 -----
        @(posedge clk);
        IN = 128'h00112233445566778899AABBCCDDEEFF;   // Fill
//        enable = 1;
        //69C4E0D86A7B0430D8CDB78070B4C55A

        // ----- INPUT 1 -----
        @(posedge clk);
        IN = 128'h00112233445566000099AABBCCDDEEFF;   // Fill
//        enable = 1;
        //818E5127D2F7B75A1380BF3C70DF47ED


        // ----- INPUT 2 -----
        @(posedge clk);
        IN = 128'h66542233445566000099AABBCCDDEEFF;   // Fill
//        enable = 1;
        //BEB0796011FC79B11F2708F8EC037700

        // ----- INPUT 3 -----
        @(posedge clk);
        IN = 128'h00000000000000000000000000000000;   // Fill
//enable = 1;
        //C6A13B37878F5B826F4F8162A1C8D879


        // ----- INPUT 4 -----
        @(posedge clk);
        IN = 128'h11111111111111111111111111111111;   // Fill
//        enable = 1;
        //35D14E6D3E3A279CF01E343E34E7DED3

        // ----- INPUT 5 -----
        @(posedge clk);
        IN = 128'h10101010101010101010101010101010;   // Fill
 //       enable = 1;
        //954F64F2E4E86E9EEE82D20216684899


        // ----- INPUT 6 -----
        @(posedge clk);
        IN = 128'h01010101010101010101010101010101;   // Fill
   //     enable = 1;
        //C352805754237F311AC0FFF4E3E03E78


        // ----- INPUT 7 -----
        @(posedge clk);
        IN = 128'h05050505050505050505050505050505;   // Fill
 //       enable = 1;
        //EA5E61AE8167CAA0586388EB9A7CB755


        // ----- INPUT 8 -----
        @(posedge clk);
        IN = 128'hffffffffffffffffffffffffffffffff;   // Fill
   //     enable = 1;
        //3C441F32CE07822364D7A2990E50BB13


        // ----- INPUT 9 -----
        @(posedge clk);
        IN = 128'h33333333333333333333333333333333;   // Fill
    //    enable = 1;
        //AA7F07422BD898330D8BDB89D3099CDE


        // ----- INPUT 10 -----
        @(posedge clk);
        IN = 128'hcccccccccccccccccccccccccccccccc;   // Fill
// enable = 1;
        //AEB05C6BB162066E45E078946DB82C7F


        // Done sending — turn enable off
        @(posedge clk);
//        enable = 0;
        IN = 0;

        // Wait for pipeline to flush
        repeat(40) @(posedge clk);

        $finish;
    end

    

endmodule
