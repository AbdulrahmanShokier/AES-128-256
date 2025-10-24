`timescale 1ns/1ps

module first_round_tb;

    // Inputs
    reg [127:0] pt;
    reg [127:0] k0;
    reg [127:0] k1;

    // Output
    wire [127:0] ct_after_1st_round;

    // Instantiate the DUT (Device Under Test)
    first_round DUT (
        .pt(pt),
        .k0(k0),
        .k1(k1),
        .ct_after_1st_round(ct_after_1st_round)
    );

    initial begin
        // --- Test case based on AES official example (FIPS-197, Appendix B) ---
        pt = 128'h00112233445566778899aabbccddeeff; // Plaintext
        k0 = 128'h000102030405060708090a0b0c0d0e0f; // Round Key 0
        k1 = 128'hd6aa74fdd2af72fadaa678f1d6ab76fe; // Round Key 1

        #10; // wait for combinational logic to settle

        $display("==========================================");
        $display(" AES FIRST ROUND TEST");
        $display("==========================================");
        $display("Input Plaintext  = %h", pt);
        $display("Round Key 0      = %h", k0);
        $display("Round Key 1      = %h", k1);
        $display("------------------------------------------");
        $display("Output after 1st round = %h", ct_after_1st_round);
        $display("Expected output (FIPS-197) = 7c16f0445566596ae43067e9d8c1a0f1");
        $display("==========================================");

        #10;
        $finish;
    end

endmodule
