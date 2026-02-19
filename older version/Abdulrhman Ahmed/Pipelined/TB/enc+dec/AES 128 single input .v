`timescale 1ns/1ps

module tb_AES_enc_dec_single_input;

    reg clk;
    reg rst;

    reg  [127:0] PT;
    reg  [127:0] KEY;
    reg          enable_enc;
    reg          enable_dec;
    reg          fsm_en_enc;
    reg          fsm_en_dec;

    reg [127:0]ct_reg;
    wire [127:0] CT;

    wire [127:0] PT_Final;

    // -------------------------------------------------
    // DUT
    // -------------------------------------------------

    always@(*)
    begin
        ct_reg = CT;
    end

    AES_enc dut1 (
        .clk(clk),
        .rst(rst),
        .IN(PT),
        .KEY(KEY),
        .enable(enable_enc),
        .fsm_en(fsm_en_enc),
        .OUT(CT)
    );


    AES_dec dut2 (
        .clk(clk),
        .rst(rst),
        .IN(ct_reg),
        .KEY(KEY),
        .enable(enable_dec),
        .fsm_en(fsm_en_dec),
        .OUT(PT_Final)
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
        enable_enc = 0;
        enable_dec = 0;
        fsm_en_enc = 0;
        fsm_en_dec = 0;
        PT = 0;

        KEY = 128'h000102030405060708090A0B0C0D0E0F;

        // Reset
        #20;
        rst = 1;

        // Trigger FSM (single pulse)
        @(posedge clk);
        fsm_en_enc = 1;
        fsm_en_dec = 1;

        @(posedge clk);
        fsm_en_enc = 0;
        fsm_en_dec = 0;

        @(posedge clk); // wait for the first key to be assigned in the register  

        @(posedge clk);
        PT = 128'h00112233445566778899aabbccddeeff;   // Fill
        enable_enc = 1;

        @(posedge clk);
        enable_enc = 0;

        repeat(9) @(posedge clk);


        @(posedge clk);
        enable_dec = 1;

        @(posedge clk);
        enable_dec = 0;

        repeat(20) @(posedge clk);

        $finish;
end

endmodule