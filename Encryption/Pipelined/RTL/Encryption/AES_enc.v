module AES_enc #(parameter BLOCK_LENGTH = 128)
(
    input                         clk,
    input                         rst,  
    input      [BLOCK_LENGTH-1:0] IN,
    input      [BLOCK_LENGTH-1:0] KEY,
    input                         valid,     
    input                         fsm_en,
    input                         symbol_tick,
    output     [BLOCK_LENGTH-1:0] OUT,
    output  reg                   valid_out   //valid output data
);

    reg [127:0] k0, k1, k2, k3, k4, k5, k6, k7, k8, k9, k10;
    wire [BLOCK_LENGTH-1:0]    r0_out, r1_out ,r2_out, r3_out, r4_out, 
                             r5_out, r6_out, r7_out, r8_out, r9_out, r10_out;
    wire         key_en;
    wire [3:0]   round_counter;                      
    wire [127:0] current_key;
    
    // Pipeline Valid Logic
    reg [10:0] en_pipe; // Pipeline to track data valid through rounds

    // Fix: previously this only shifted on ticks where `valid` itself was
    // high (a single 1-tick pulse), so the bit injected at en_pipe[0]
    // never advanced past that - the pipeline must shift every
    // symbol_tick once the pulse is in transit, not only when a fresh
    // valid arrives. Gated on symbol_tick (not bare clk, the
    // 4x-oversampled clk_sample) so it advances exactly once per real
    // round-tick, matching round_N's own symbol_tick gating below.
    always @(posedge clk) begin
        if (!rst) begin
            en_pipe <= 11'b0;
        end
        else if (symbol_tick) begin
            // Shift left every symbol_tick: LSB is input (Round 0 firing
            // this tick), MSB is output (Round 10 just fired last tick).
            en_pipe <= {en_pipe[9:0], valid};
        end
    end

    // -- Individual FF registers --
    always @(posedge clk) begin
        if (!rst)                                          k0 <= 128'b0;
        else if (symbol_tick && round_counter == 4'd1)      k0 <= KEY;
    end

    always @(posedge clk) begin
        if (!rst)                                          k1 <= 128'b0;
        else if (symbol_tick && round_counter == 4'd2)      k1 <= current_key;
    end

    always @(posedge clk) begin
        if (!rst)                                          k2 <= 128'b0;
        else if (symbol_tick && round_counter == 4'd3)      k2 <= current_key;
    end

    always @(posedge clk) begin
        if (!rst)                                          k3 <= 128'b0;
        else if (symbol_tick && round_counter == 4'd4)      k3 <= current_key;
    end

    always @(posedge clk) begin
        if (!rst)                                          k4 <= 128'b0;
        else if (symbol_tick && round_counter == 4'd5)      k4 <= current_key;
    end

    always @(posedge clk) begin
        if (!rst)                                          k5 <= 128'b0;
        else if (symbol_tick && round_counter == 4'd6)      k5 <= current_key;
    end

    always @(posedge clk) begin
        if (!rst)                                          k6 <= 128'b0;
        else if (symbol_tick && round_counter == 4'd7)      k6 <= current_key;
    end

    always @(posedge clk) begin
        if (!rst)                                          k7 <= 128'b0;
        else if (symbol_tick && round_counter == 4'd8)      k7 <= current_key;
    end

    always @(posedge clk) begin
        if (!rst)                                          k8 <= 128'b0;
        else if (symbol_tick && round_counter == 4'd9)      k8 <= current_key;
    end

    always @(posedge clk) begin
        if (!rst)                                          k9 <= 128'b0;
        else if (symbol_tick && round_counter == 4'd10)     k9 <= current_key;
    end

    always @(posedge clk) begin
        if (!rst)                                          k10 <= 128'b0;
        else if (symbol_tick && round_counter == 4'd11)     k10 <= current_key;
    end

    FSM   fsm_control (.clk(clk), .rst(rst), .fsm_en(fsm_en), .symbol_tick(symbol_tick),
                       .key_gene_en(key_en), .Round_Count(round_counter));

    key_generator  key_round (.key(KEY), .Round_Count(round_counter),
                              .clk(clk), .rst(rst), .en(key_en), .symbol_tick(symbol_tick),
                             .current_key(current_key));

    // -- Round Instances --
    // Each round only fires when the pulse has actually propagated to its
    // own pipeline stage - round0 fires on the original `valid` pulse
    // (stage 0), round1 fires when that pulse reaches en_pipe[0] (one
    // tick later), round2 on en_pipe[1], etc. Previously every round
    // instance was wired to the same raw `valid` signal, so they all
    // tried to fire on the same single tick instead of one-per-tick in
    // sequence.
    round_0        round0  (.clk(clk), .rst(rst), .IN(IN),     .KEY(k0),  .valid(en_pipe[0]),   .symbol_tick(symbol_tick), .OUT(r0_out));
    rounds_1_to_9  round1  (.clk(clk), .rst(rst), .IN(r0_out), .KEY(k1),  .valid(en_pipe[1]),   .symbol_tick(symbol_tick), .OUT(r1_out));
    rounds_1_to_9  round2  (.clk(clk), .rst(rst), .IN(r1_out), .KEY(k2),  .valid(en_pipe[2]),   .symbol_tick(symbol_tick), .OUT(r2_out));
    rounds_1_to_9  round3  (.clk(clk), .rst(rst), .IN(r2_out), .KEY(k3),  .valid(en_pipe[3]),   .symbol_tick(symbol_tick), .OUT(r3_out));
    rounds_1_to_9  round4  (.clk(clk), .rst(rst), .IN(r3_out), .KEY(k4),  .valid(en_pipe[4]),   .symbol_tick(symbol_tick), .OUT(r4_out));
    rounds_1_to_9  round5  (.clk(clk), .rst(rst), .IN(r4_out), .KEY(k5),  .valid(en_pipe[5]),   .symbol_tick(symbol_tick), .OUT(r5_out));
    rounds_1_to_9  round6  (.clk(clk), .rst(rst), .IN(r5_out), .KEY(k6),  .valid(en_pipe[6]),   .symbol_tick(symbol_tick), .OUT(r6_out));
    rounds_1_to_9  round7  (.clk(clk), .rst(rst), .IN(r6_out), .KEY(k7),  .valid(en_pipe[7]),   .symbol_tick(symbol_tick), .OUT(r7_out));
    rounds_1_to_9  round8  (.clk(clk), .rst(rst), .IN(r7_out), .KEY(k8),  .valid(en_pipe[8]),   .symbol_tick(symbol_tick), .OUT(r8_out));
    rounds_1_to_9  round9  (.clk(clk), .rst(rst), .IN(r8_out), .KEY(k9),  .valid(en_pipe[9]),   .symbol_tick(symbol_tick), .OUT(r9_out));
    round_10       round10 (.clk(clk), .rst(rst), .IN(r9_out), .KEY(k10), .valid(en_pipe[10]),  .symbol_tick(symbol_tick), .OUT(r10_out));

    // Outputs 
//     assign valid_out = en_pipe[10]; // Output is valid when pipeline is full


        always @(posedge clk) begin
        if (!rst) begin
            valid_out <= 11'b0;
        end
        else if (symbol_tick) begin
            // Shift left every symbol_tick: LSB is input (Round 0 firing
            // this tick), MSB is output (Round 10 just fired last tick).
            valid_out <= en_pipe[10];
        end
    end

    
    assign OUT = (valid_out)? r10_out : 128'b0;

endmodule