`timescale 1ns/1ps

module tb_AES_enc_dec_full_pipeline;

    reg clk;
    reg rst;

    reg  [127:0] PT;
    reg  [127:0] KEY;
    reg          enable_enc;
    reg          enable_dec;
    reg          fsm_en_enc;
    reg          fsm_en_dec;

    wire [127:0] CT;
    wire [127:0] PT_Final;

    // -------------------------------------------------
    // Test vector storage
    // -------------------------------------------------
    reg [127:0] test_pt      [0:10];
    reg [127:0] expected_ct  [0:10];
    reg [127:0] saved_pt;
    integer i;
    integer pass_enc, fail_enc;
    integer pass_dec, fail_dec;

    // -------------------------------------------------
    // DUT
    // -------------------------------------------------
    AES_enc dut1 (
        .clk(clk),
        .rst(rst),
        .IN(PT),
        .KEY(KEY),
        .enable(enable_enc),      // Connected to drive validity
        .fsm_en(fsm_en_enc),
        .OUT(CT)
    );


    AES_dec dut2 (
        .clk(clk),
        .rst(rst),
        .IN(CT),
        .KEY(KEY),
        .enable(enable_dec),      // Connected to drive validity
        .fsm_en(fsm_en_dec),
        .OUT(PT_Final)
    );


    // -------------------------------------------------
    // Clock
    // -------------------------------------------------
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // -------------------------------------------------
    // Stimulus
    // -------------------------------------------------
    initial begin

        // ---- Initialise test vectors ----
        test_pt[0]      = 128'h00112233445566778899AABBCCDDEEFF;
        expected_ct[0]  = 128'h69C4E0D86A7B0430D8CDB78070B4C55A;

        test_pt[1]      = 128'h00112233445566000099AABBCCDDEEFF;
        expected_ct[1]  = 128'h818E5127D2F7B75A1380BF3C70DF47ED;

        test_pt[2]      = 128'h66542233445566000099AABBCCDDEEFF;
        expected_ct[2]  = 128'hBEB0796011FC79B11F2708F8EC037700;

        test_pt[3]      = 128'h00000000000000000000000000000000;
        expected_ct[3]  = 128'hC6A13B37878F5B826F4F8162A1C8D879;

        test_pt[4]      = 128'h11111111111111111111111111111111;
        expected_ct[4]  = 128'h35D14E6D3E3A279CF01E343E34E7DED3;

        test_pt[5]      = 128'h10101010101010101010101010101010;
        expected_ct[5]  = 128'h954F64F2E4E86E9EEE82D20216684899;

        test_pt[6]      = 128'h01010101010101010101010101010101;
        expected_ct[6]  = 128'hC352805754237F311AC0FFF4E3E03E78;

        test_pt[7]      = 128'h05050505050505050505050505050505;
        expected_ct[7]  = 128'hEA5E61AE8167CAA0586388EB9A7CB755;

        test_pt[8]      = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        expected_ct[8]  = 128'h3C441F32CE07822364D7A2990E50BB13;

        test_pt[9]      = 128'h33333333333333333333333333333333;
        expected_ct[9]  = 128'hAA7F07422BD898330D8BDB89D3099CDE;

        test_pt[10]     = 128'hCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC;
        expected_ct[10] = 128'hAEB05C6BB162066E45E078946DB82C7F;

        // ---- Reset ----
        rst        = 0;
        enable_enc = 0;
        enable_dec = 0;
        fsm_en_enc = 0;
        fsm_en_dec = 0;
        PT         = 0;
        KEY        = 128'h000102030405060708090A0B0C0D0E0F;
        pass_enc   = 0;
        fail_enc   = 0;
        pass_dec   = 0;
        fail_dec   = 0;

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


        // =============================================
        // Loop over all 11 test cases
        // =============================================
        for (i = 0; i < 11; i = i + 1) begin

            // ---------- Encryption ----------
            @(posedge clk);
            PT         = test_pt[i];
            saved_pt   = test_pt[i];
            enable_enc = 1;

            @(posedge clk);
            enable_enc = 0;

            // Wait for encryption to finish (8 more rounds)
            repeat (8) @(posedge clk);

            // Check cipher-text
           

            // ---------- Decryption ----------
            @(posedge clk);
            enable_dec = 1;

            @(posedge clk);
            enable_dec = 0;
                   
            
            // Wait for decryption to finish (8 more rounds)
            repeat (9) @(posedge clk);


            // Small gap before next test case
            repeat (2) @(posedge clk);
        end

        $finish;
    end

endmodule