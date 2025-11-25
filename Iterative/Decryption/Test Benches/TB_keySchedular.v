`timescale 1ns/1ps

module TB_keySchedular;

    reg clk;
    reg [1:0] control_signal;
    reg [127:0] load_key_in;
    reg [3:0] round_number;
    wire [127:0] round_key_out;

    // Instantiate DUT
    AES_key_schedular DUT (
        .clk(clk),
        .control_signal(control_signal),
        .load_key_in(load_key_in),
        .round_number(round_number),
        .round_key_out(round_key_out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Storage for keys
    reg [127:0] forward_keys [0:10];
    reg [127:0] reverse_keys [0:10];
    integer i;

    initial begin
        // ----- INITIAL LOAD -----
        control_signal = 2'b01;   // Load key
        load_key_in = 128'h00000000000000000000000000000000; // all zeros
        round_number = 0;

        @(posedge clk);
        @(posedge clk);

        // -------------------------
        //     FORWARD 
        // -------------------------
        control_signal = 2'b10;

        for (i = 0; i <= 10; i = i + 1) begin
            round_number = i;
            @(posedge clk);
            forward_keys[i] = round_key_out;
            $display("Forward Round %0d | Input = %h | Output = %h", i, load_key_in, round_key_out);
        end

        // -------------------------
        //     REVERSE 
        // -------------------------
        control_signal = 2'b11;

        // Use a simple downward counting for loop
        for (i = 10; i >= 0; i = i - 1) begin
            round_number = i;
            @(posedge clk);
            reverse_keys[i] = round_key_out;
            $display("Reverse Round %0d | Input = %h | Output = %h", i, forward_keys[i], round_key_out);
        end

        $display("\n=== TEST COMPLETE ===");
        $stop;
    end

endmodule
