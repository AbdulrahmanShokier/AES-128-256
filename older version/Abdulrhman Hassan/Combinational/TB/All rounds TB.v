`timescale 1ns/1ps


// testing code with key are already given


module aes_all_rounds_keys_ready_tb;

    // Inputs
    reg  [127:0] pt;

    // All round keys from AES standard (FIPS-197 Example)
    reg  [127:0] k0, k1, k2, k3, k4, k5, k6, k7, k8, k9, k10;

    // Intermediate outputs
    wire [127:0] r1_out, r2_out, r3_out, r4_out, r5_out, r6_out, r7_out, r8_out, r9_out, final_ct;

    // -----------------------------
    // Encryption rounds
    // -----------------------------
    first_round ROUND1 (.pt(pt), .k0(k0), .k1(k1), .ct_after_1st_round(r1_out));
    mid_rounds  ROUND2 (.pt(r1_out), .kn_minus_1(k2), .ct_after_nth_round(r2_out));
    mid_rounds  ROUND3 (.pt(r2_out), .kn_minus_1(k3), .ct_after_nth_round(r3_out));
    mid_rounds  ROUND4 (.pt(r3_out), .kn_minus_1(k4), .ct_after_nth_round(r4_out));
    mid_rounds  ROUND5 (.pt(r4_out), .kn_minus_1(k5), .ct_after_nth_round(r5_out));
    mid_rounds  ROUND6 (.pt(r5_out), .kn_minus_1(k6), .ct_after_nth_round(r6_out));
    mid_rounds  ROUND7 (.pt(r6_out), .kn_minus_1(k7), .ct_after_nth_round(r7_out));
    mid_rounds  ROUND8 (.pt(r7_out), .kn_minus_1(k8), .ct_after_nth_round(r8_out));
    mid_rounds  ROUND9 (.pt(r8_out), .kn_minus_1(k9), .ct_after_nth_round(r9_out));
    last_round  ROUND10(.pt(r9_out), .kn(k10), .ct(final_ct));

    // -----------------------------
    // Stimulus
    // -----------------------------
    initial begin
        // Example plaintext (AES standard)
        pt  = 128'h00112233445566778899aabbccddeeff;

        // Round keys from FIPS-197 Example A.1
        k0  = 128'h000102030405060708090a0b0c0d0e0f;
        k1  = 128'hd6aa74fdd2af72fadaa678f1d6ab76fe;
        k2  = 128'hb692cf0b643dbdf1be9bc5006830b3fe;
        k3  = 128'hb6ff744ed2c2c9bf6c590cbf0469bf41;
        k4  = 128'h47f7f7bc95353e03f96c32bcfd058dfd;
        k5  = 128'h3caaa3e8a99f9deb50f3af57adf622aa;
        k6  = 128'h5e390f7df7a69296a7553dc10aa31f6b;
        k7  = 128'h14f9701ae35fe28c440adf4d4ea9c026;
        k8  = 128'h47438735a41c65b9e016baf4aebf7ad2;
        k9  = 128'h549932d1f08557681093ed9cbe2c974e;
        k10 = 128'h13111d7fe3944a17f307a78b4d2b30c5;

        #10;
        $display("=====================================================");
        $display(" AES-128 ENCRYPTION (Keys Ready Test) ");
        $display("=====================================================");
        $display("Plaintext  = %h", pt);
        $display("-----------------------------------------------------");
        $display("Round 1 Output = %h", r1_out);
        $display("Round 2 Output = %h", r2_out);
        $display("Round 3 Output = %h", r3_out);
        $display("Round 4 Output = %h", r4_out);
        $display("Round 5 Output = %h", r5_out);
        $display("Round 6 Output = %h", r6_out);
        $display("Round 7 Output = %h", r7_out);
        $display("Round 8 Output = %h", r8_out);
        $display("Round 9 Output = %h", r9_out);
        $display("-----------------------------------------------------");
        $display("Final CipherText = %h", final_ct);
        $display("Expected          = 69C4E0D86A7B0430D8CDB78070B4C55A");
        $display("=====================================================");

        #5;
        if (final_ct === 128'h69C4E0D86A7B0430D8CDB78070B4C55A)
            $display("✅ AES ENCRYPTION SUCCESS!");
        else
            $display("❌ AES ENCRYPTION FAILED!");

        #10;
        $finish;
    end

endmodule
