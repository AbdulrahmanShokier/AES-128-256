`timescale 1ns / 1ps
// =============================================================================
// gf_arith.v  —  GF(2^8) Arithmetic Primitives
//
// Field  : GF(2^8)
// Primitive polynomial : p(x) = x^8 + x^4 + x^3 + x^2 + 1  (hex 0x11D)
// Primitive root alpha : 0x02
//
// Modules exported:
//   gf_mult  – fully combinational 8-bit × 8-bit multiplier
//   gf_inv   – fully combinational multiplicative inverse
// =============================================================================

// -----------------------------------------------------------------------------
// gf_mult : combinational GF(2^8) multiplier using shift-and-XOR
//
//  Shift a left by one bit  =  multiply by alpha.
//  If the discarded (degree-8) bit was 1, XOR with 0x1D  (= p(x) - x^8)
//  to reduce back into the field. 
//  Repeat for each bit of b.
// -----------------------------------------------------------------------------
module gf_mult (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] prod
);
    // r[i] = a * alpha^i  in GF(2^8),  fully unrolled
    wire [7:0] r [0:7];
    assign r[0] = a;
    assign r[1] = r[0][7] ? {r[0][6:0], 1'b0} ^ 8'h1D : {r[0][6:0], 1'b0};
    assign r[2] = r[1][7] ? {r[1][6:0], 1'b0} ^ 8'h1D : {r[1][6:0], 1'b0};
    assign r[3] = r[2][7] ? {r[2][6:0], 1'b0} ^ 8'h1D : {r[2][6:0], 1'b0};
    assign r[4] = r[3][7] ? {r[3][6:0], 1'b0} ^ 8'h1D : {r[3][6:0], 1'b0};
    assign r[5] = r[4][7] ? {r[4][6:0], 1'b0} ^ 8'h1D : {r[4][6:0], 1'b0};
    assign r[6] = r[5][7] ? {r[5][6:0], 1'b0} ^ 8'h1D : {r[5][6:0], 1'b0};
    assign r[7] = r[6][7] ? {r[6][6:0], 1'b0} ^ 8'h1D : {r[6][6:0], 1'b0};

    // Conditionally accumulate r[i] based on bit i of b
    wire [7:0] p [0:7];
    assign p[0] = b[0] ? r[0]         : 8'h00;
    assign p[1] = b[1] ? r[1] ^ p[0]  : p[0];
    assign p[2] = b[2] ? r[2] ^ p[1]  : p[1];
    assign p[3] = b[3] ? r[3] ^ p[2]  : p[2];
    assign p[4] = b[4] ? r[4] ^ p[3]  : p[3];
    assign p[5] = b[5] ? r[5] ^ p[4]  : p[4];
    assign p[6] = b[6] ? r[6] ^ p[5]  : p[5];
    assign p[7] = b[7] ? r[7] ^ p[6]  : p[6];

    assign prod = p[7];
endmodule


// -----------------------------------------------------------------------------
// gf_inv : GF(2^8) multiplicative inverse via Fermat's little theorem
//
//  a^{-1} = a^{2^8 - 2} = a^{254}   (since a^{255} = 1 for a != 0)
//  254 = 2 + 4 + 8 + 16 + 32 + 64 + 128
//
//  Strategy: compute a^2, a^4, ..., a^128 by repeated squaring (7 mults),
//  then chain-multiply them all together (6 more mults) to get a^{254}.
//  Total: 13 gf_mult instances, purely combinational.
//
//  Returns 0x00 for input 0x00 (inverse of 0 is undefined; safe don't-care).
// -----------------------------------------------------------------------------


//=============================================================================
// getting the inverse using Fermat's Little Theorem.
// a^{p-1} = 1 mod p
// a^{-1} = a^{p-2} mod p
// then a^{-1} = a^{254} mod p(X)
// p(X) = x^8 + x^4 + x^3 + x^2 + 1 which was the primative polynomial for GF(2^8)
// we are doing thi rather than haivng a LUT for inverse of each alpha power  
// 254 = 2 + 4 + 8 + 16 + 32 + 64 + 128
// the order of opreation is based on square and multiply method.
//=============================================================================
module gf_inv (
    input  wire [7:0] a,
    output wire [7:0] inv
);
    wire [7:0] a2, a4, a8, a16, a32, a64, a128;
    wire [7:0] t0, t1, t2, t3, t4;

    // ---- Squaring chain ----
    gf_mult sq1 (.a(a),    .b(a),    .prod(a2));    // a^2
    gf_mult sq2 (.a(a2),   .b(a2),   .prod(a4));    // a^4
    gf_mult sq3 (.a(a4),   .b(a4),   .prod(a8));    // a^8
    gf_mult sq4 (.a(a8),   .b(a8),   .prod(a16));   // a^16
    gf_mult sq5 (.a(a16),  .b(a16),  .prod(a32));   // a^32
    gf_mult sq6 (.a(a32),  .b(a32),  .prod(a64));   // a^64
    gf_mult sq7 (.a(a64),  .b(a64),  .prod(a128));  // a^128

    // ---- Accumulation: a^254 = a^2 * a^4 * a^8 * a^16 * a^32 * a^64 * a^128 ----
    gf_mult m1 (.a(a2),   .b(a4),    .prod(t0));    // a^6
    gf_mult m2 (.a(t0),   .b(a8),    .prod(t1));    // a^14
    gf_mult m3 (.a(t1),   .b(a16),   .prod(t2));    // a^30
    gf_mult m4 (.a(t2),   .b(a32),   .prod(t3));    // a^62
    gf_mult m5 (.a(t3),   .b(a64),   .prod(t4));    // a^126
    gf_mult m6 (.a(t4),   .b(a128),  .prod(inv));   // a^254

endmodule
