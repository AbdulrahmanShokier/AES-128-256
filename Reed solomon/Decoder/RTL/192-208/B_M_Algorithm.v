`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// Berlekamp-Massey key-equation solver for RS(208,192).
// Inputs:  S1..S16 packed in syndromes[8*i +: 8], where i=0 => S1.
// Outputs: Lambda polynomial packed as lambda[8*i +: 8], i=0..8.
// Maximum correction capability T=8.
// reset is active-low.
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

function [7:0] gf_pow_elem;
    input [7:0] a;
    input integer power;
    reg [7:0] result;
    integer k;
    begin
        result = 8'h01;
        for (k = 0; k < power; k = k + 1)
            result = gf_mult(result, a);
        gf_pow_elem = result;
    end
endfunction

function [7:0] gf_inverse;
    input [7:0] a;
    begin
        if (a == 8'h00)
            gf_inverse = 8'h00;
        else
            gf_inverse = gf_pow_elem(a, 254);
    end
endfunction

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
                d = S_arr[n];

                for (i = 1; i <= T; i = i + 1) begin
                    if (i <= L_int)
                        d = d ^ gf_mult(C[i], S_arr[n-i]);
                end

                if (d != 8'h00) begin
                    for (i = 0; i <= T; i = i + 1)
                        Tpoly[i] = C[i];

                    coef = gf_mult(d, gf_inverse(b));

                    for (i = 0; i <= T; i = i + 1) begin
                        if ((i + m) <= T)
                            C[i+m] = C[i+m] ^ gf_mult(coef, B[i]);
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
