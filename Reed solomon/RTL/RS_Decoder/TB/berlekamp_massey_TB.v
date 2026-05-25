`timescale 1ns / 1ps

module tb_berlekamp_massey;

    // Inputs
    reg clk;
    reg rst_n;
    reg start;
    reg [255:0] syn_in;

    // Outputs
    wire [127:0] lambda;
    wire [4:0] err_count;
    wire done;

    // Instantiate the Unit Under Test (UUT)
    berlekamp_massey #(
        .T2(32)
    ) uut (
        .clk(clk), 
        .rst_n(rst_n), 
        .start(start), 
        .syn_in(syn_in), 
        .lambda(lambda), 
        .err_count(err_count), 
        .done(done)
    );

    // Clock generation (50MHz)
    always #10 clk = ~clk;

    // Internal tracking variables for the print table
    integer i;
    reg [7:0] current_c;

    initial begin
        // Initialize Inputs
        clk = 0;
        rst_n = 0;
        start = 0;
        syn_in = 0;

        // Wait 100 ns for global reset to finish
        #100;
        rst_n = 1;
        #20;

        // Create a test case syndrome pattern 
        // For RS(255,223), we have 32 syndrome bytes (S0 to S31)
        // Let's inject a mock error syndrome pattern where S0=1, S1=1, S2=a^5 (0x20 in hex representation)
        syn_in = 256'h0;
        syn_in[0*8  +: 8] = 8'h01; // S0 = 1
        syn_in[1*8  +: 8] = 8'h01; // S1 = 1
        syn_in[2*8  +: 8] = 8'h20; // S2 = 8'h20 (representing an alpha power alpha^5)
        // Remaining syndromes default to 0x00

        // Trigger the Berlekamp-Massey core
        $display("\n--- STARTING BERLEKAMP-MASSEY ALGORITHM ---");
        $display(" mu |  d_mu  | Llen | x_reg | b_reg | C Polynomial Coefficients (C[0] to C[4])");
        $display("-----------------------------------------------------------------------------");
        
        start = 1;
        #20;
        start = 0;

        // Monitor internal states at each clock cycle to generate the textbook table
        while (!done) begin
            @(posedge clk);
            // Print the internal values right after they update on the clock edge
            #1; 
            if (uut.running) begin
                $write("%3d |   %02h   |  %2d  |   %2d  |   %02h  | ", 
                        uut.r_cnt, uut.bm_d, uut.Llen, uut.x_reg, uut.b_reg);
                
                // Print the first few coefficients of the error locator polynomial
                $write("1 + %02hX + %02hX^2 + %02hX^3\n", uut.C[1], uut.C[2], uut.C[3]);
            end
        end

        // Wait for final done flag consolidation
        @(posedge clk);
        #1;
        $display("-----------------------------------------------------------------------------");
        $display("ALGORITHM COMPLETE");
        $display("Detected Error Count: %d", err_count);
        $display("Final Lambda Output (Hex): %h", lambda);
        
        #100;
        $finish;
    end
      
endmodule