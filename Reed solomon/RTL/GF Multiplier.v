module gf_multiplier #(
    parameter m = 8
)(
    input  [m-1:0] op_a,
    input  [m-1:0] op_b,
    output [m-1:0] result
);

// Primitive polynomial for GF(2^8): x^8 + x^4 + x^3 + x^2 + 1
// Reduction polynomial (lower 8 bits): 0x1D
localparam [m-1:0] PRIM_POLY = 8'h1D;

// Precompute op_a * x^i for i = 0 to 7
wire [m-1:0] a_x0, a_x1, a_x2, a_x3, a_x4, a_x5, a_x6, a_x7;

// a * x^0 = a
assign a_x0 = op_a;

// a * x^1: shift left, reduce if overflow
assign a_x1 = a_x0[7] ? ({a_x0[6:0], 1'b0} ^ PRIM_POLY) : {a_x0[6:0], 1'b0};

// a * x^2
assign a_x2 = a_x1[7] ? ({a_x1[6:0], 1'b0} ^ PRIM_POLY) : {a_x1[6:0], 1'b0};

// a * x^3
assign a_x3 = a_x2[7] ? ({a_x2[6:0], 1'b0} ^ PRIM_POLY) : {a_x2[6:0], 1'b0};

// a * x^4
assign a_x4 = a_x3[7] ? ({a_x3[6:0], 1'b0} ^ PRIM_POLY) : {a_x3[6:0], 1'b0};

// a * x^5
assign a_x5 = a_x4[7] ? ({a_x4[6:0], 1'b0} ^ PRIM_POLY) : {a_x4[6:0], 1'b0};

// a * x^6
assign a_x6 = a_x5[7] ? ({a_x5[6:0], 1'b0} ^ PRIM_POLY) : {a_x5[6:0], 1'b0};

// a * x^7
assign a_x7 = a_x6[7] ? ({a_x6[6:0], 1'b0} ^ PRIM_POLY) : {a_x6[6:0], 1'b0};

// Result = sum of (op_b[i] * a_x[i]) for all i
assign result = (op_b[0] ? a_x0 : 8'h00) ^
                (op_b[1] ? a_x1 : 8'h00) ^
                (op_b[2] ? a_x2 : 8'h00) ^
                (op_b[3] ? a_x3 : 8'h00) ^
                (op_b[4] ? a_x4 : 8'h00) ^
                (op_b[5] ? a_x5 : 8'h00) ^
                (op_b[6] ? a_x6 : 8'h00) ^
                (op_b[7] ? a_x7 : 8'h00);

endmodule