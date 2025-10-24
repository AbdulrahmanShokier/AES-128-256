`timescale 1ns / 1ps

module shift_row_tb;

    // Input and output signals
    reg  [127:0] substituted_state_array;
    wire [127:0] shifted_state_array;

    // Instantiate the module
    shift_row uut (
        .substituted_state_array(substituted_state_array),
        .shifted_state_array(shifted_state_array)
    );

    initial begin
        $display("======================================");
        $display(" AES ShiftRows Test ");
        $display("======================================");

        // Test input (column-major order)
        // Bytes: 00 11 22 33 44 55 66 77 88 99 aa bb cc dd ee ff
        substituted_state_array = 128'h00112233445566778899aabbccddeeff;

        #10; // wait for output to settle

        $display("Input  (before ShiftRows) = %h", substituted_state_array);
        $display("Output (after  ShiftRows) = %h", shifted_state_array);

        // Expected result (after ShiftRows only)
        // |00 44 88 cc|
        // |11 55 99 dd|
        // |22 66 aa ee|
        // |33 77 bb ff|
        // =>
        // |00 55 aa ff|
        // |44 99 ee 33|
        // |88 dd 22 77|
        // |cc 11 66 bb|
        // => 0055aaff4499ee3388dd2277cc1166bb
        if (shifted_state_array == 128'h0055aaff4499ee3388dd2277cc1166bb)
            $display("✅ ShiftRows PASSED!");
        else
            $display("❌ ShiftRows FAILED!");

        $display("======================================");
        $finish;
    end

endmodule
