`timescale 1ns / 1ps

module sub_bytes_tb;

    // Input and output signals
    reg  [127:0] resultant_state_array;
    wire [127:0] substituted_state_array;

    // Instantiate the module under test (UUT)
    sub_bytes uut (
        .resultant_state_array(resultant_state_array),
        .substituted_state_array(substituted_state_array)
    );

    initial begin
        $display("======================================");
        $display(" AES SubBytes Test ");
        $display("======================================");

        // Test input (example from FIPS-197)
        // Input = 19 a0 9a e9 3d f4 c6 f8 e3 e2 8d 48 be 2b 2a 08
        resultant_state_array = 128'h19a09ae93df4c6f8e3e28d48be2b2a08;

        #10; // wait for S-box to compute

        $display("Input  (before SubBytes) = %h", resultant_state_array);
        $display("Output (after  SubBytes) = %h", substituted_state_array);

        // Expected output after SubBytes
        // Expected = d4 e0 b8 1e bf b4 41 27 5d 52 11 98 30 ae f1 e5
        if (substituted_state_array == 128'hd4e0b81e27bfb44111985d52aef1e530)
            $display("✅ SubBytes (linear) PASSED!");
        else
            $display("❌ SubBytes (linear) FAILED!");

        $display("======================================");
        $finish;
    end

endmodule
