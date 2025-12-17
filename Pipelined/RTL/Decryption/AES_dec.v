module AES_dec #(parameter BLOCK_LENGTH = 128)
(
    input                         clk,
    input                         rst,  
    input      [BLOCK_LENGTH-1:0] IN,
    input      [BLOCK_LENGTH-1:0] KEY,
    input                         enable, //to turn on/off the round
    input                         fsm_en,
    output     [BLOCK_LENGTH-1:0] OUT
);



wire [BLOCK_LENGTH-1:0]  r0_out, r1_out ,r2_out, r3_out, r4_out, 
                         r5_out, r6_out, r7_out, r8_out, r9_out, r10_out;


wire       key_en;
wire [3:0] round_counter;

wire [127:0] k0, k1 ,k2, k3, k4, k5, 
     k6, k7, k8, k9, k10;

reg [10:0] en_pipe; // enable pipeline: en_pipe[0] is for round0, en_pipe[1] for round1, ..., en_pipe[10] for round10
                    // it was made of reg type to be saved and to move the value with it's plain text pair
                    //between stages for all rounds


always@(*)
begin
    if (!rst) 
    begin
        en_pipe[0] = 1'b0;
    end
    
    else
    begin
        en_pipe[0] = enable;
    end
end

always @(posedge clk or negedge rst) 
begin
    if (!rst) 
    begin
        en_pipe[10:1] <= 11'b0;
    end 

    else 
    begin
        en_pipe[10:1] <= en_pipe[9:0]; // shift enable down the pipeline
    end
end


FSM   fsm_control (.clk(clk), .rst(rst), .fsm_en(fsm_en), .key_gene_en(key_en), .Round_Count(round_counter));



key_generator_dec  key_round (.key(KEY), .Round_Count(round_counter), .clk(clk), .rst(rst), .en(key_en),
                             .k0(k0), .k1(k1), .k2(k2), .k3(k3), .k4(k4),
                             .k5(k5), .k6(k6), .k7(k7), .k8(k8), .k9(k9), .k10(k10));


round_10_dec       round10(.clk(clk), .rst(rst), .IN(IN), .KEY(k10), .enable(en_pipe[0]), .OUT(r10_out));


rounds_9_to_1_dec  round9 (.clk(clk), .rst(rst), .IN(r10_out), .KEY(k9), .enable(en_pipe[1]),.OUT(r9_out));


rounds_9_to_1_dec  round8 (.clk(clk), .rst(rst), .IN(r9_out), .KEY(k8), .enable(en_pipe[2]), .OUT(r8_out));


rounds_9_to_1_dec  round7 (.clk(clk), .rst(rst), .IN(r8_out), .KEY(k7), .enable(en_pipe[3]), .OUT(r7_out));


rounds_9_to_1_dec  round6 (.clk(clk), .rst(rst), .IN(r7_out), .KEY(k6), .enable(en_pipe[4]), .OUT(r6_out));


rounds_9_to_1_dec  round5 (.clk(clk), .rst(rst), .IN(r6_out), .KEY(k5), .enable(en_pipe[5]), .OUT(r5_out));


rounds_9_to_1_dec  round4 (.clk(clk), .rst(rst), .IN(r5_out), .KEY(k4), .enable(en_pipe[6]), .OUT(r4_out));


rounds_9_to_1_dec  round3 (.clk(clk), .rst(rst), .IN(r4_out), .KEY(k3), .enable(en_pipe[7]), .OUT(r3_out));


rounds_9_to_1_dec  round2 (.clk(clk), .rst(rst), .IN(r3_out), .KEY(k2), .enable(en_pipe[8]), .OUT(r2_out));


rounds_9_to_1_dec  round1 (.clk(clk), .rst(rst), .IN(r2_out), .KEY(k1), .enable(en_pipe[9]), .OUT(r1_out));


round_0_dec        round0 (.clk(clk), .rst(rst), .IN(r1_out), .KEY(k0), .enable(en_pipe[10]), .OUT(r0_out));



assign OUT = r0_out;


endmodule