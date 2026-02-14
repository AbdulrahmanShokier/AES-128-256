`timescale 1ns/1ps

module tb_key_gen_with_fsm();

    reg clk;
    reg rst;
    reg fsm_en;

    reg  [127:0] key;
    wire [3:0]   Round_Count;
    wire         key_gene_en;

    // Generated keys
    wire [1407:0] all_keys;

    wire [127:0] k0;
    wire [127:0] k1;
    wire [127:0] k2;
    wire [127:0] k3;
    wire [127:0] k4;
    wire [127:0] k5;
    wire [127:0] k6;
    wire [127:0] k7;
    wire [127:0] k8;
    wire [127:0] k9;
    wire [127:0] k10;

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

        .keys(all_keys)
    );

    assign k0  = all_keys[ 127:   0];
    assign k1  = all_keys[ 255: 128];
    assign k2  = all_keys[ 383: 256];
    assign k3  = all_keys[ 511: 384];
    assign k4  = all_keys[ 639: 512];
    assign k5  = all_keys[ 767: 640];
    assign k6  = all_keys[ 895: 768];
    assign k7  = all_keys[1023: 896];
    assign k8  = all_keys[1151:1024];
    assign k9  = all_keys[1279:1152];
    assign k10 = all_keys[1407:1280];


    //////////////////////////////////////
    // Stimulus
    //////////////////////////////////////
    initial begin
    // Initialize
    rst     = 0;
    fsm_en  = 0;
    key     = 128'h000102030405060708090a0b0c0d0e0f;

    #10 rst = 1; // release reset

    #10 fsm_en = 1;   // start pulse
    #10 fsm_en = 0;   // end after one clock

    wait (uut_fsm.current_state == 2'b10); // reach HOLD state

    #40


    $stop;
end


endmodule



/*
working 
*/