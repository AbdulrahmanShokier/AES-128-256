

module mixC_tb;

    reg  [127:0] in_data;
    wire [127:0] out_data;

    // Instantiate the DUT (Device Under Test)
    mix_columns uut (
        .IN(in_data),
        .OUT(out_data)
    );

    initial begin

        in_data = 128'h23CF4FE2640701621280BF7ECE2C05D3;

		
        #10; // wait 10ns for combinational logic to settle
        $stop;
    end

endmodule