`timescale 1ns/1ps

module tb_AES_Decryption;

    // DUT Inputs
    reg clk;
    reg rst_n;
    reg En;
    reg [127:0] CT;
    reg [127:0] K_i;
    reg [3:0]   Round_Number;

    // DUT Output
    wire [127:0] PT;
    wire Valid;

    // Instantiate DUT
    AES_Decryption DUT (
        .CLK(clk),
        .RST(rst_n),
        .En(En),
        .CT(CT),
        .K_i(K_i),
        .Round_Number(Round_Number),
        .PT(PT),
        .Valid(Valid)
    );

    // Clock gen
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ------------------------------
    // Round Keys (10 → 0)
    // ------------------------------
    reg [127:0] round_keys [0:10];

    initial begin
        round_keys[10] = 128'hd014f9a8c9ee2589e13f0cc8b6630ca6;
        round_keys[9]  = 128'hac7766f319fadc2128d12941575c006e;
        round_keys[8]  = 128'head27321b58dbad2312bf5607f8d292f;
        round_keys[7]  = 128'h4e54f70e5f5fc9f384a64fb24ea6dc4f;
        round_keys[6]  = 128'h6d88a37a110b3efddbf98641ca0093fd;
        round_keys[5]  = 128'hd4d1c6f87c839d87caf2b8bc11f915bc;
        round_keys[4]  = 128'hef44a541a8525b7fb671253bdb0bad00;
        round_keys[3]  = 128'h3d80477d4716fe3e1e237e446d7a883b;
        round_keys[2]  = 128'hf2c295f27a96b9435935807a7359f67f;
        round_keys[1]  = 128'ha0fafe1788542cb123a339392a6c7605;
        round_keys[0]  = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    end

    // Ciphertext
    localparam [127:0] CIPHERTEXT = 128'h3925841d02dc09fbdc118597196a0b32;

    // Simulation logic
    integer r;
    initial begin
        // Init
        rst_n = 0;
        En = 0;
        CT = 0;
        K_i = 0;
        Round_Number = 0;

        // Release reset
        #20 rst_n = 1;

        // Load ciphertext only once
        CT = CIPHERTEXT;
        @(posedge clk);
        @(posedge clk);
        En = 1;
        

        // ----------------------------------------
        // Run rounds 10 → 0
        // ----------------------------------------
        for (r = 10; r >= 0; r = r - 1) begin
            Round_Number = r;
            K_i = round_keys[r];

            @(posedge clk);

            // Print internal wires each cycle
            $display("\n===============================");
            $display(" Round %0d", r);
            $display("===============================");
            $display("CT_reg                 = %h", DUT.CT_reg);
            $display("Inv_AddKey_Out         = %h", DUT.Inv_AddKey_Out);
            $display("Inv_MixCol_Out         = %h", DUT.Inv_MixCol_Out);
            $display("SEL_InvShiftRows_input = %h", DUT.SEL_InvShiftRows_input);
            $display("Inv_ShiftRow_Out       = %h", DUT.Inv_ShiftRow_Out);
            $display("Inv_SubByte_Out        = %h", DUT.Inv_SubByte_Out);
            $display("CT_next                = %h", DUT.CT_next);
            $display("PT (CT_reg)            = %h", PT);
            $display("Valid                  = %b", Valid);

            #1; // small delay so display ordering is correct
        end

        // Wait 1 cycle after last round
        @(posedge clk);

        $display("\n################################");
        $display("# FINAL PLAINTEXT = %h", PT);
        $display("# VALID = %b", Valid);
        $display("################################");

        $stop;
    end

endmodule
