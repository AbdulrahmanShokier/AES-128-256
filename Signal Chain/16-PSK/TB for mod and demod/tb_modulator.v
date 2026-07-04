`timescale 1ns / 1ps

module tb_modulator;

    reg clk;
    reg rst;
    reg tx_valid_in;
    reg [3:0] tx_data_in;

    wire signed [15:0] I_out;
    wire signed [15:0] Q_out;

    // Memory array for 16 symbols
    reg [3:0] symbol_mem [0:15];
    integer i;

    // Clock generation (50 MHz)
    always #10 clk = ~clk;

    // Modulator Instantiation
    top_16psk_baseband #(
        .DATA_WIDTH(16),
        .FRAC_WIDTH(14),
        .NO_BITS(4),
        .UPS_FACTOR(4),
        .COUNTER_WIDTH(2),
        .NUM_TAPS(65),
        .COEFF_WIDTH(16)
    ) UUT (
        .clk_sample(clk),
        .rst(rst),
        .valid_in(tx_valid_in),
        .data_in(tx_data_in),
        .I_out(I_out),
        .Q_out(Q_out)
    );

    initial begin
        clk = 0;
        rst = 0;
        tx_valid_in = 0;
        tx_data_in = 0;

        // Load data from text file
        $readmemb("symbols.txt", symbol_mem);

        // Reset pulse
        #100;
        rst = 1;
        #40;

        // Feed each symbol into the pipeline
        for (i = 0; i < 16; i = i + 1) begin
            if(i==0) @(posedge clk); // Wait for the first clock edge
            @(posedge clk);
            tx_data_in = symbol_mem[i];
            tx_valid_in = 1'b1;

            // Maintain valid for one cycle
            @(posedge clk);
            tx_valid_in = 1'b0;
            
            // Wait three cycles for the next symbol
            repeat(2) @(posedge clk);
        end

        // Wait to observe final outputs
        #2000;
        $finish;
    end

endmodule