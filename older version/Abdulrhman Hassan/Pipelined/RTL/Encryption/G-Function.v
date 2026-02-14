module g_function
(   
    input      clk,
    input      rst,
    input  [31:0] word_3,
    input  [7 :0] round_number,
    output [31:0] word_3_substituted
);

wire [7:0] v0;
wire [7:0] v1;
wire [7:0] v2;
wire [7:0] v3;


S_box v3_out (.in_byte(word_3[7 : 0]) , .out_byte(v3), .clk(clk), .rst(rst));
S_box v2_out (.in_byte(word_3[15: 8]) , .out_byte(v2), .clk(clk), .rst(rst));
S_box v1_out (.in_byte(word_3[23:16]) , .out_byte(v1), .clk(clk), .rst(rst));
S_box v0_out (.in_byte(word_3[31:24]) , .out_byte(v0), .clk(clk), .rst(rst));

assign word_3_substituted = {v1 ^ round_number,v2,v3,v0} ;


endmodule

/*

v0 اكبر ببايت هو اللي في ال 

*/