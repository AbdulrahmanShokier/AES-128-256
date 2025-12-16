`timescale 1ns/1ps

module tb_AES_dec_single_in;

    reg clk;
    reg rst;

    reg  [127:0] IN;
    reg  [127:0] KEY;
    reg          enable;
    reg          fsm_en;

    wire [127:0] OUT;

    // -------------------------------------------------
    // Instance of DUT
    // -------------------------------------------------
    AES_dec dut (
        .clk(clk),
        .rst(rst),
        .IN(IN),
        .KEY(KEY),
        .enable(enable),
        .fsm_en(fsm_en),
        .OUT(OUT)
    );

    // -------------------------------------------------
    // Clock Generator
    // -------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;   // 100MHz
    end

    // -------------------------------------------------
    // Stimulus
    // -------------------------------------------------
    initial begin
        // Initialize
        rst     = 0;
        enable  = 0;
        fsm_en  = 0;
        IN      = 0;
        KEY     = 128'h000102030405060708090a0b0c0d0e0f;

        // Reset sequence
        #20;
        rst = 1;

        // ---------------------------------------
        // 1) Send fsm_en = 1 for ONE clock only
        // ---------------------------------------
        @(posedge clk);
        fsm_en = 1;

        @(posedge clk);
        fsm_en = 0;   // FSMS only triggered by 1-cycle pulse

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




        // ---------------------------------------
        // 2) Apply IN + enable on same cycle
        // ---------------------------------------
        @(posedge clk);
        IN = 128'h69C4E0D86A7B0430D8CDB78070B4C55A;
        enable = 1;
        //00112233445566778899AABBCCDDEEFF

        // Keep enable for one cycle only
        @(posedge clk);
        enable = 0;

        // Wait enough cycles for all rounds to complete
        repeat(50) @(posedge clk);

        $finish;
    end

endmodule
