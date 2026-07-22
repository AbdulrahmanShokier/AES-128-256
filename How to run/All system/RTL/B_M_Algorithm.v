`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// Berlekamp-Massey key-equation solver for RS(208,192).
// Inputs:  S1..S16 packed in syndromes[8*i +: 8], where i=0 => S1.
// Outputs: Lambda polynomial packed as lambda[8*i +: 8], i=0..8.
// Maximum correction capability T=8.
// reset is active-low.
//
// XST FIX APPLIED:
// - No direct negative-risk syndrome indexing is used.
// - No direct out-of-range dynamic write to C[] is used.
// - All for-loops have synthesis-friendly constant bounds.
// - REPLACED 254-iteration inverse loop with square-and-multiply to prevent XST memory crash.
// -----------------------------------------------------------------------------
module B_M_Algorithm (
    input              clk,
    input              reset,
    input              clk_en,
    input              start,
    input      [127:0] syndromes,
    output reg [71:0]  lambda,
    output reg [5:0]   L,
    output reg         done,
    output reg         uncorrectable
);

parameter NSYM = 16;
parameter T    = 8;

reg [7:0] S_arr [0:15];
reg [7:0] C     [0:8];
reg [7:0] B     [0:8];
reg [7:0] Tpoly [0:8];

integer i;
integer n;
integer L_int;
integer m;
reg [7:0] b;
reg [7:0] d;
reg [7:0] coef;

function [7:0] gf_mult;
    input [7:0] a;
    input [7:0] b_in;
    reg [15:0] aa;
    reg [7:0]  bb;
    reg [15:0] p;
    integer k;
    begin
        aa = {8'h00, a};
        bb = b_in;
        p  = 16'h0000;
        for (k = 0; k < 8; k = k + 1) begin
            if (bb[0])
                p = p ^ aa;
            if (aa[7])
                aa = (aa << 1) ^ 16'h011D;
            else
                aa = (aa << 1);
            bb = bb >> 1;
        end
        gf_mult = p[7:0];
    end
endfunction

// --- XST FIX: EXPONENTIATION BY SQUARING ---
// Mathematically computes a^254 in 13 steps instead of 254 loop iterations.
function [7:0] gf_inverse;
    input [7:0] a;
    reg [7:0] a2, a4, a8, a16, a32, a64, a128;
    reg [7:0] p1, p2, p3, p4, p5;
    begin
        if (a == 8'h00) begin
            gf_inverse = 8'h00;
        end else begin
            a2   = gf_mult(a, a);
            a4   = gf_mult(a2, a2);
            a8   = gf_mult(a4, a4);
            a16  = gf_mult(a8, a8);
            a32  = gf_mult(a16, a16);
            a64  = gf_mult(a32, a32);
            a128 = gf_mult(a64, a64);

            p1 = gf_mult(a128, a64);
            p2 = gf_mult(p1, a32);
            p3 = gf_mult(p2, a16);
            p4 = gf_mult(p3, a8);
            p5 = gf_mult(p4, a4);
            gf_inverse = gf_mult(p5, a2);
        end
    end
endfunction
// -------------------------------------------

function [7:0] get_S_safe;
    input integer idx;
    begin
        case (idx)
            0:  get_S_safe = S_arr[0];
            1:  get_S_safe = S_arr[1];
            2:  get_S_safe = S_arr[2];
            3:  get_S_safe = S_arr[3];
            4:  get_S_safe = S_arr[4];
            5:  get_S_safe = S_arr[5];
            6:  get_S_safe = S_arr[6];
            7:  get_S_safe = S_arr[7];
            8:  get_S_safe = S_arr[8];
            9:  get_S_safe = S_arr[9];
            10: get_S_safe = S_arr[10];
            11: get_S_safe = S_arr[11];
            12: get_S_safe = S_arr[12];
            13: get_S_safe = S_arr[13];
            14: get_S_safe = S_arr[14];
            15: get_S_safe = S_arr[15];
            default: get_S_safe = 8'h00;
        endcase
    end
endfunction

task update_C_safe;
    input integer idx;
    input [7:0] value_to_xor;
    begin
        case (idx)
            0: C[0] = C[0] ^ value_to_xor;
            1: C[1] = C[1] ^ value_to_xor;
            2: C[2] = C[2] ^ value_to_xor;
            3: C[3] = C[3] ^ value_to_xor;
            4: C[4] = C[4] ^ value_to_xor;
            5: C[5] = C[5] ^ value_to_xor;
            6: C[6] = C[6] ^ value_to_xor;
            7: C[7] = C[7] ^ value_to_xor;
            8: C[8] = C[8] ^ value_to_xor;
            default: begin
            end
        endcase
    end
endtask

always @(posedge clk) begin
    if (!reset) begin
        lambda        <= 72'd0;
        L             <= 6'd0;
        done          <= 1'b0;
        uncorrectable <= 1'b0;
    end else begin
        if (clk_en) begin
            done <= 1'b0;

            if (start) begin
                uncorrectable <= 1'b0;

                for (i = 0; i < NSYM; i = i + 1)
                    S_arr[i] = syndromes[8*i +: 8];

                for (i = 0; i <= T; i = i + 1) begin
                    C[i]     = 8'h00;
                    B[i]     = 8'h00;
                    Tpoly[i] = 8'h00;
                end

                C[0] = 8'h01;
                B[0] = 8'h01;
                L_int = 0;
                m     = 1;
                b     = 8'h01;

                for (n = 0; n < NSYM; n = n + 1) begin
                    d = get_S_safe(n);

                    for (i = 1; i <= T; i = i + 1) begin
                        if ((i <= L_int) && (i <= n))
                            d = d ^ gf_mult(C[i], get_S_safe(n - i));
                    end

                    if (d != 8'h00) begin
                        for (i = 0; i <= T; i = i + 1)
                            Tpoly[i] = C[i];

                        coef = gf_mult(d, gf_inverse(b));

                        for (i = 0; i <= T; i = i + 1) begin
                            update_C_safe(i + m, gf_mult(coef, B[i]));
                        end

                        if ((2 * L_int) <= n) begin
                            L_int = n + 1 - L_int;
                            for (i = 0; i <= T; i = i + 1)
                                B[i] = Tpoly[i];
                            b = d;
                            m = 1;
                        end else begin
                            m = m + 1;
                        end
                    end else begin
                        m = m + 1;
                    end
                end

                for (i = 0; i <= T; i = i + 1)
                    lambda[8*i +: 8] <= C[i];

                if (L_int > T) begin
                    L             <= 6'd8;
                    uncorrectable <= 1'b1;
                end else begin
                    L             <= L_int[5:0];
                    uncorrectable <= 1'b0;
                end

                done <= 1'b1;
            end
        end
    end
end

endmodule
