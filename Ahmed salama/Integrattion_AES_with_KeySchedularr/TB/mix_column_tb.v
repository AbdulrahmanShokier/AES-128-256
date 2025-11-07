`timescale 1ns/1ps

module mix_columns_tb;

    reg  [127:0] in_data;
    wire [127:0] out_data;

    // Instantiate the DUT (Device Under Test)
    mix_columns uut (
        .IN(in_data),
        .OUT(out_data)
    );

    initial begin
        $display("===== AES MixColumns Testbench =====");

        // Example AES state input (can use any 128-bit pattern)
        in_data = 128'hd4bf5d30e0b452aeb84111f11e2798e5;

        #10; // wait 10ns for combinational logic to settle

        $display("Input : %h", in_data);
        $display("Output: %h", out_data);

        // Another test vector
        in_data = 128'hd49db8735b43953897f02d2f177de961a;
        #10;
        $display("Input : %h", in_data);
        $display("Output: %h", out_data);

        $finish;
    end

endmodule
