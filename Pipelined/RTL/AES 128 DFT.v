module AES_enc_dec;

    reg clk;
    reg rst;

    reg  [127:0] PT;
    reg  [127:0] KEY;

    reg          enable_enc;
    reg          enable_dec;

    reg          fsm_en_enc;
    reg          fsm_en_dec;

    reg          enc_valid;
    reg          dec_valid;

    wire [127:0] CT;
    wire [127:0] PT_Final;


    // -------------------------------------------------
    // DUTs
    // -------------------------------------------------
    AES_enc dut1 (
        .clk(clk),
        .rst(rst),
        .IN(PT),
        .KEY(KEY),
        .enable(enable_enc),      // Connected to drive validity
        .fsm_en(fsm_en_enc),
        .OUT(CT),
        .valid_out(enc_valid)
    );


    AES_dec dut2 (
        .clk(clk),
        .rst(rst),
        .IN(CT),
        .KEY(KEY),
        .enable(enable_dec),      // Connected to drive validity
        .fsm_en(fsm_en_dec),
        .OUT(PT_Final),
        .valid_out(dec_valid)
    );


endmodule