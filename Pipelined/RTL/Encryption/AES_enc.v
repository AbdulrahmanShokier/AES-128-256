module AES_enc #(parameter BLOCK_LENGTH = 128)
(
    input                         clk,
    input                         rst,  
    input      [BLOCK_LENGTH-1:0] IN,
    input      [BLOCK_LENGTH-1:0] KEY,
    input                         enable, //to turn on/off the round
    output reg [BLOCK_LENGTH-1:0] OUT
);



wire [BLOCK_LENGTH-1:0]  r0_out, r1_out ,r2_out, r3_out, r4_out, 
                         r5_out, r6_out, r7_out, r8_out, r9_out, r10_out;



wire [BLOCK_LENGTH-1:0] k0, k1 ,k2, k3, k4, k5, 
                        k6, k7, k8, k9, k10; // keys output of the key generator 



wire v0, v1 ,v2, v3, v4, v5, 
     v6, v7, v8, v9, v10; // It's a signal to activate the key generator on the -ve edge of the clock
                          // to get the key of the next round 
                          //(not implemenatable on the FPGA we have but its working till find another idea)



wire en1 ,en2, en3, en4, en5, 
     en6, en7, en8, en9, en10;  // to move the enable signal between the rounds                        



reg [10:0] en_pipe; // enable pipeline: en_pipe[0] is for round0, en_pipe[1] for round1, ..., en_pipe[10] for round10
                    // it was made of reg type to be saved and to move the value with it's plain text pair
                    //between stages for all rounds





always @(posedge clk or negedge rst) 
begin
    if (!rst) 
    begin
        en_pipe <= 11'b0;
    end 

    else 
    begin
        en_pipe[0] <= enable;
        en_pipe[10:1] <= en_pipe[9:0]; // shift enable down the pipeline
    end
end

key_generator       key_round0 (.key(KEY), .round_number(8'h0), .clk(clk), .rst(rst), .valid(v0), .sub_key(k0));

round_0             round0 (.clk(clk), .rst(rst), .IN(IN), .KEY(k0), .enable(en_pipe[0]), .next_round_enable(en1), .OUT(r0_out), .valid(v0));



key_generator       key_round1 (.key(k0), .round_number(8'h1), .clk(clk), .rst(rst), .valid(v1), .sub_key(k1));

rounds_1_to_9       round1 (.clk(clk), .rst(rst), .IN(r0_out), .KEY(k1), .enable(en_pipe[1]), .next_round_enable(en2),.OUT(r1_out), .valid(v1));



key_generator       key_round2 (.key(k1), .round_number(8'h2), .clk(clk), .rst(rst), .valid(v2), .sub_key(k2));

rounds_1_to_9       round2 (.clk(clk), .rst(rst), .IN(r1_out), .KEY(k2), .enable(en_pipe[2]), .next_round_enable(en3), .OUT(r2_out), .valid(v2));



key_generator       key_round3 (.key(k2), .round_number(8'h4), .clk(clk), .rst(rst), .valid(v3), .sub_key(k3));

rounds_1_to_9       round3 (.clk(clk), .rst(rst), .IN(r2_out), .KEY(k3), .enable(en_pipe[3]), .next_round_enable(en4), .OUT(r3_out), .valid(v3));



key_generator       key_round4 (.key(k3), .round_number(8'h8), .clk(clk), .rst(rst), .valid(v4), .sub_key(k4));

rounds_1_to_9       round4 (.clk(clk), .rst(rst), .IN(r3_out), .KEY(k4), .enable(en_pipe[4]), .next_round_enable(en5), .OUT(r4_out), .valid(v4));



key_generator       key_round5 (.key(k4), .round_number(8'h10), .clk(clk), .rst(rst), .valid(v5), .sub_key(k5));

rounds_1_to_9       round5 (.clk(clk), .rst(rst), .IN(r4_out), .KEY(k5), .enable(en_pipe[5]), .next_round_enable(en6), .OUT(r5_out), .valid(v5));



key_generator       key_round6 (.key(k5), .round_number(8'h20), .clk(clk), .rst(rst), .valid(v6), .sub_key(k6));

rounds_1_to_9       round6 (.clk(clk), .rst(rst), .IN(r5_out), .KEY(k6), .enable(en_pipe[6]), .next_round_enable(en7), .OUT(r6_out), .valid(v6));



key_generator       key_round7 (.key(k6), .round_number(8'h40), .clk(clk), .rst(rst), .valid(v7), .sub_key(k7));

rounds_1_to_9       round7 (.clk(clk), .rst(rst), .IN(r6_out), .KEY(k7), .enable(en_pipe[7]), .next_round_enable(en8), .OUT(r7_out), .valid(v7));



key_generator       key_round8 (.key(k7), .round_number(8'h80), .clk(clk), .rst(rst), .valid(v8), .sub_key(k8));

rounds_1_to_9       round8 (.clk(clk), .rst(rst), .IN(r7_out), .KEY(k8), .enable(en_pipe[8]), .next_round_enable(en9), .OUT(r8_out), .valid(v8));



key_generator       key_round9 (.key(k8), .round_number(8'h1B), .clk(clk), .rst(rst), .valid(v9), .sub_key(k9));

rounds_1_to_9       round9 (.clk(clk), .rst(rst), .IN(r8_out), .KEY(k9), .enable(en_pipe[9]), .next_round_enable(en10), .OUT(r9_out), .valid(v9));



key_generator       key_round10 (.key(k9), .round_number(8'h36), .clk(clk), .rst(rst), .valid(v10), .sub_key(k10));

round_10           round10 (.clk(clk), .rst(rst), .IN(r9_out), .KEY(k10), .enable(en_pipe[10]), .OUT(r10_out), .valid(v10));



always@(*)
begin
    OUT <= r10_out;
end

endmodule