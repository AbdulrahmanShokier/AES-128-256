`timescale 1ns/1ps

module tb_FSM_controller;

    // Inputs
    reg clk;
    reg rst_n;
    reg vaild_in;
    reg [127:0] key_in;

    // Outputs
    wire vaild_out;
    wire [3:0] round_count_to_keyExp;
    wire [127:0] KeyOut_KeyExpLoad;
    wire [1:0] KeyExp_control;
    wire Decryptor_en;

    // Dummy echo for key expansion roundkey
    wire [127:0] KeyExp_RoundKey;
    assign KeyExp_RoundKey = KeyOut_KeyExpLoad;

    // DUT
    FSM_controller DUT (
        .clk(clk),
        .rst_n(rst_n),
        .vaild_in(vaild_in),
        .key_in(key_in),
        .vaild_out(vaild_out),
        .round_count_to_keyExp(round_count_to_keyExp),
        .KeyOut_KeyExpLoad(KeyOut_KeyExpLoad),
        .KeyExp_RoundKey(KeyExp_RoundKey),
        .KeyExp_control(KeyExp_control),
        .Decryptor_en(Decryptor_en)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    integer i;

    initial begin
        // --------------------------------------------------
        // Initial values + RESET sequence
        // --------------------------------------------------
        rst_n     = 0;
        vaild_in  = 0;
        key_in    = 0;

        #20;
        rst_n = 1;
        @(posedge clk);

        // --------------------------------------------------
        // FIRST transaction
        // --------------------------------------------------
        key_in   = 128'hAABBCCDDEEFF00112233445566778899;
        vaild_in = 1;
        @(posedge clk);
        vaild_in = 0;

        $display("\n--- FIRST RUN ---");
        for(i = 0; i < 35; i = i + 1) begin
            @(posedge clk);
            $display("T=%0t | STATE=%b | RND=%d | CTRL=%b | DEC_EN=%b | valid_out=%b",
                $time, DUT.current_state, round_count_to_keyExp,
                KeyExp_control, Decryptor_en, vaild_out);
        end

        // --------------------------------------------------
        // SECOND transaction with SAME KEY
        // --------------------------------------------------
        $display("\n--- SECOND RUN (same key) ---");

        vaild_in = 1;
        @(posedge clk);
        vaild_in = 0;

        for(i = 0; i < 35; i = i + 1) begin
            @(posedge clk);
            $display("T=%0t | STATE=%b | RND=%d | CTRL=%b | DEC_EN=%b | valid_out=%b",
                $time, DUT.current_state, round_count_to_keyExp,
                KeyExp_control, Decryptor_en, vaild_out);
        end

        // --------------------------------------------------
        // FINISH
        // --------------------------------------------------
        $display("\nSimulation Finished.");
        $finish;
    end

endmodule