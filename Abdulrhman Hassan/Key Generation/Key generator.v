module key_generator
(
    input  [127:0] key,
    input  [7 : 0] round_number,
    output [127:0] round_key
);

wire [31:0] w0, w1, w2, w3;
wire [31:0] g_out;
wire [31:0] w4, w5, w6, w7;

assign w0 = key[127:96];
assign w1 = key[95:64];
assign w2 = key[63:32];
assign w3 = key[31:0];

g_function g_func (.word_3(w3), .round_number(round_number), .word_3_substituted(g_out));

assign w4 = w0 ^ g_out;
assign w5 = w1 ^ w4;
assign w6 = w2 ^ w5;
assign w7 = w3 ^ w6;

assign round_key = {w4, w5, w6, w7};


endmodule