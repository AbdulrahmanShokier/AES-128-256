`timescale 1ns / 1ps

module psk16_psk16_DecisionDevice_tb;

    // Inputs
    reg clk;
    reg rst;
    reg signed [15:0] I;
    reg signed [15:0] Q;

    // Outputs
    wire [3:0] symbol;
    wire [15:0] angle_wave;

    // Instantiate the Unit Under Test (UUT)
    psk16_psk16_DecisionDevice uut (
        .clk(clk),
        .rst(rst),
        .I(I),
        .Q(Q),
        .symbol(symbol),
        .angle_wave(angle_wave)  // angle_wave is not used in the testbench
    );

    // Clock generation (100 MHz)
    always #5 clk = ~clk;

    // File handling variables
    integer file_handle;
    integer status;
    reg signed [15:0] i_val;
    reg signed [15:0] q_val;

    initial begin
        // Initialize inputs
        clk = 0;
        rst = 1;
        I = 0;
        Q = 0;

        // Apply reset
        #20;
        rst = 0;
        @(posedge clk);

        // Open the test vector file
        file_handle = $fopen("iq_vectors.txt", "r");
        if (file_handle == 0) begin
            $display("Error: Could not open iq_vectors.txt");
            $finish;
        end

        // Read and apply vectors sequentially
        while (!$feof(file_handle)) begin
            status = $fscanf(file_handle, "%d %d\n", i_val, q_val);
            if (status == 2) begin
                I = i_val;
                Q = q_val;
                @(posedge clk);
            end
        end

        // Wait for the final pipeline stages to complete
        #100;

        // Close the file and end simulation
        $fclose(file_handle);
        $display("Simulation finished successfully.");
        $finish;
    end

    // Monitor outputs in the console
    initial begin
        $monitor("Time = %0t | I = %d, Q = %d | Symbol = %b", $time, I, Q, symbol);
    end

endmodule
