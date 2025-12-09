`timescale 1ns/1ps

module tb_FSM;

    reg clk;
    reg rst;
    reg fsm_en;

    wire key_gene_en;
    wire [3:0] Round_Count;

    // Instantiate DUT
    FSM DUT (
        .clk(clk),
        .rst(rst),
        .fsm_en(fsm_en),
        .key_gene_en(key_gene_en),
        .Round_Count(Round_Count)
    );

    // Clock generator (10ns period)
    always #5 clk = ~clk;

    initial begin
        // Initial values
        clk     = 0;
        rst     = 0;
        fsm_en  = 0;

        // Apply reset
        #20 rst = 1;

        // One-cycle enable pulse
        #15 fsm_en = 1;   // start pulse
        #10 fsm_en = 0;   // end after one clock

        // Let FSM complete counter and enter hold
        #150;

        // Restart sequence: another one-cycle pulse
        #10 fsm_en = 1;
        #10 fsm_en = 0;

        #150;

        $stop;
    end

    // Monitor output changes
    initial begin
        $monitor("t=%0t | rst=%b | fsm_en=%b | key_gene_en=%b | Round_Count=%d",
                  $time, rst, fsm_en, key_gene_en, Round_Count);
    end

endmodule
