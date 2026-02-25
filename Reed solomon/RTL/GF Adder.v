module gf_adder #(
    parameter m = 8
)(
    input  [m-1 : 0] op_a,
    input  [m-1 : 0] op_b,
    output [m-1 : 0] result
);

assign result = op_a ^ op_b;

endmodule