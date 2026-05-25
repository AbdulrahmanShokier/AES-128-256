`timescale 1ns / 1ps

module syndrome_calc_TB;

    // Clock and control signals
    reg clk;
    reg rst_n;
    reg clr;
    reg [7:0] data_in;
    reg data_valid;

    // Massive Hex string storage (255 bytes * 8 bits = 2040 bits)
    reg [2039:0] rx_hex_input;

    // Outputs
    wire [255:0] syn_out;
    wire done;

    // Loop variable
    integer i;

    // Instantiate the Unit Under Test (UUT)
    syndrome_calc uut (
        .clk(clk),
        .rst_n(rst_n),
        .clr(clr),
        .data_in(data_in),
        .data_valid(data_valid),
        .syn_out(syn_out),
        .done(done)
    );

    // Clock generation (10 ns period / 100 MHz)
    always #5 clk = ~clk;

    initial begin
        $display("--- Starting Sequential Syndrome Calculator Test ---");

        // Initialize signals
        clk = 0;
        rst_n = 0;
        clr = 0;
        data_in = 8'h00;
        data_valid = 0;

        // Assign the massive Hex string
        rx_hex_input = 2040'h68656C6C6F20776F726C640000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000A218D2E076180DC935EEB2DB401FBBE0B0D1FD1EE461E22801F4D2B3805CA972;

        // Hold reset for a few cycles
        #20;
        rst_n = 1;
        #10;

        // Feed data byte-by-byte
        // Send 255 bytes total. Start from the highest order coefficient.
        for (i = 254; i >= 0; i = i - 1) begin
            @(posedge clk);
            data_in = rx_hex_input[i*8 +: 8];
            data_valid = 1;
        end

        // Stop feeding data
        @(posedge clk);
        data_valid = 0;

        // Wait for the done flag to process the final outputs
        wait (done == 1'b1);
        @(posedge clk);

        $display("Test Complete.");
        $display("Actual Syndromes  : %h", syn_out);
        
        #20;
        $finish;
    end
      
endmodule