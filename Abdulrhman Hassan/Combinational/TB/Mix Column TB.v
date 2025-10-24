`timescale 1ns/1ps

module mix_columns_tb;

// Inputs
reg  [127:0] shifted_state_array;

// Output
wire [127:0] mixed_state_array;

// Instantiate the Unit Under Test (UUT)
mix_columns uut (
    .shifted_state_array(shifted_state_array),
    .mixed_state_array(mixed_state_array)
);

initial begin
    $display("----------------------------------------------------");
    $display(" AES MixColumns Testbench ");
    $display("----------------------------------------------------");

    // Test vector from FIPS-197, Section 5.1.3
    // Input (after ShiftRows):
    //  D4 E0 B8 1E
    //  BF B4 41 27
    //  5D 52 11 98
    //  30 AE F1 E5
    //
    // Output (after MixColumns):
    //  04 E0 48 28
    //  66 CB F8 06
    //  81 19 D3 26
    //  E5 9A 7A 4C

    shifted_state_array = 128'hD4E0B81EBFB441275D52119830AEF1E5;

    #10; // Wait for combinational logic

    $display("Input  (ShiftRows out) = %h", shifted_state_array);
    $display("Output (MixColumns out) = %h", mixed_state_array);
    $display("Expected Output         = 04E0482866CBF8068119D326E59A7A4C");

    // Optional: Automatic check
    if (mixed_state_array == 128'h04E0482866CBF8068119D326E59A7A4C)
        $display("✅ MixColumns PASSED!");
    else
        $display("❌ MixColumns FAILED!");

    $display("----------------------------------------------------");
    #10;
    $stop;
end

endmodule
