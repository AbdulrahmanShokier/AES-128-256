module AES_enc #(parameter BLOCK_LENGTH = 128)
(
    input                         clk,
    input                         rst,  
    input      [BLOCK_LENGTH-1:0] IN,
    input      [BLOCK_LENGTH-1:0] KEY,
    input                         enable,     
    input                         fsm_en,
    output     [BLOCK_LENGTH-1:0] OUT,
    output                        valid_out   //valid output data
);

    reg [127:0] k0, k1, k2, k3, k4, k5, k6, k7, k8, k9, k10;
    wire [BLOCK_LENGTH-1:0]    r0_out, r1_out ,r2_out, r3_out, r4_out, 
                             r5_out, r6_out, r7_out, r8_out, r9_out, r10_out;
    wire         key_en;
    wire [3:0]   round_counter;                      
    wire [127:0] current_key;
    
    // Pipeline Valid Logic
    reg [10:0] en_pipe; // Pipeline to track data valid through rounds

    always @(posedge clk) begin
        if (!rst) begin
            en_pipe <= 11'b0;
        end 
        else begin
             // Shift enable left: LSB is input (Round 0), MSB is output (Round 10)
            en_pipe <= {en_pipe[9:0], enable};
        end
    end

    // ── Individual FF registers ──
    always @(posedge clk) begin
        if (!rst)                       k0 <= 128'b0;
        else if (round_counter == 4'd1) k0 <= KEY;
    end

    always @(posedge clk) begin
        if (!rst)                       k1 <= 128'b0;
        else if (round_counter == 4'd2) k1 <= current_key;
    end

    always @(posedge clk) begin
        if (!rst)                       k2 <= 128'b0;
        else if (round_counter == 4'd3) k2 <= current_key;
    end

    always @(posedge clk) begin
        if (!rst)                       k3 <= 128'b0;
        else if (round_counter == 4'd4) k3 <= current_key;
    end

    always @(posedge clk) begin
        if (!rst)                       k4 <= 128'b0;
        else if (round_counter == 4'd5) k4 <= current_key;
    end

    always @(posedge clk) begin
        if (!rst)                       k5 <= 128'b0;
        else if (round_counter == 4'd6) k5 <= current_key;
    end

    always @(posedge clk) begin
        if (!rst)                       k6 <= 128'b0;
        else if (round_counter == 4'd7) k6 <= current_key;
    end

    always @(posedge clk) begin
        if (!rst)                       k7 <= 128'b0;
        else if (round_counter == 4'd8) k7 <= current_key;
    end

    always @(posedge clk) begin
        if (!rst)                       k8 <= 128'b0;
        else if (round_counter == 4'd9) k8 <= current_key;
    end

    always @(posedge clk) begin
        if (!rst)                       k9 <= 128'b0;
        else if (round_counter == 4'd10) k9 <= current_key;
    end

    always @(posedge clk) begin
        if (!rst)                        k10 <= 128'b0;
        else if (round_counter == 4'd11) k10 <= current_key;
    end


    FSM   fsm_control (.clk(clk), .rst(rst), .fsm_en(fsm_en), 
                       .key_gene_en(key_en), .Round_Count(round_counter));
                       
    key_generator  key_round (.key(KEY), .Round_Count(round_counter), 
                             .clk(clk), .rst(rst), .en(key_en), 
                             .current_key(current_key));

    // ── Round Instances ──
    round_0        round0 (.clk(clk), .rst(rst), .IN(IN), .KEY(k0), .OUT(r0_out));
    rounds_1_to_9  round1 (.clk(clk), .rst(rst), .IN(r0_out), .KEY(k1), .OUT(r1_out));
    rounds_1_to_9  round2 (.clk(clk), .rst(rst), .IN(r1_out), .KEY(k2), .OUT(r2_out));
    rounds_1_to_9  round3 (.clk(clk), .rst(rst), .IN(r2_out), .KEY(k3), .OUT(r3_out));
    rounds_1_to_9  round4 (.clk(clk), .rst(rst), .IN(r3_out), .KEY(k4), .OUT(r4_out));
    rounds_1_to_9  round5 (.clk(clk), .rst(rst), .IN(r4_out), .KEY(k5), .OUT(r5_out));
    rounds_1_to_9  round6 (.clk(clk), .rst(rst), .IN(r5_out), .KEY(k6), .OUT(r6_out));
    rounds_1_to_9  round7 (.clk(clk), .rst(rst), .IN(r6_out), .KEY(k7), .OUT(r7_out));
    rounds_1_to_9  round8 (.clk(clk), .rst(rst), .IN(r7_out), .KEY(k8), .OUT(r8_out));
    rounds_1_to_9  round9 (.clk(clk), .rst(rst), .IN(r8_out), .KEY(k9), .OUT(r9_out));
    round_10       round10 (.clk(clk), .rst(rst), .IN(r9_out), .KEY(k10), .OUT(r10_out));

    // Outputs 
    assign OUT = (valid_out)? r10_out : 128'b0;
    assign valid_out = en_pipe[10]; // Output is valid when pipeline is full

endmodule