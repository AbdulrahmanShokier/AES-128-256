`timescale 1ns/1ps

module tb_key_gen_with_fsm();

    reg clk;
    reg rst;
    reg fsm_en;

    reg  [127:0] key;
    wire [3:0]   Round_Count;
    wire         key_gene_en;

    // Generated keys
    wire [127:0] k0, k1, k2, k3, k4, k5, k6, k7, k8, k9, k10;

    //////////////////////////////////////
    //  Clock Generation
    //////////////////////////////////////
    initial begin
        clk = 0;
        forever #5 clk = ~clk;   // 100 MHz clock
    end

    //////////////////////////////////////
    //  DUT Instantiation — FSM
    //////////////////////////////////////
    FSM uut_fsm (
        .clk(clk),
        .rst(rst),
        .fsm_en(fsm_en),
        .key_gene_en(key_gene_en),
        .Round_Count(Round_Count)
    );

    //////////////////////////////////////
    //  DUT Instantiation — Key Generator
    //////////////////////////////////////
    key_generator #(128) uut_keygen (
        .clk(clk),
        .rst(rst),
        .en(key_gene_en),       // IMPORTANT: Controlled by FSM
        .key(key),              // initial input key
        .Round_Count(Round_Count),

        .k0(k0),
        .k1(k1),
        .k2(k2),
        .k3(k3),
        .k4(k4),
        .k5(k5),
        .k6(k6),
        .k7(k7),
        .k8(k8),
        .k9(k9),
        .k10(k10)
    );

    //////////////////////////////////////
    // Stimulus
    //////////////////////////////////////
    initial begin
    // Initialize
    rst     = 0;
    fsm_en  = 0;
    key     = 128'h00010203040506070809550b0c0d0e77;

    #10 rst = 1; // release reset

    #10 fsm_en = 1; // pulse start

    wait (uut_fsm.current_state == 2'b10); // reach HOLD state


    $stop;
end


endmodule



/*
working 
*/