`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// Syndrome calculator for RS(208,192), GF(2^8), primitive polynomial 0x11D.
// Calculates S1..S16 for roots alpha^1..alpha^16.
// Input is one received symbol per clock while enable=1.
// reset is active-low.
// -----------------------------------------------------------------------------
module Syndrome (
    input              clk,
    input              reset,
    input              enable,
    input      [7:0]   received_symbol,
    output     [127:0] syndromes,
    output reg         syndromes_ready
);

parameter N      = 208;
parameter NSYM   = 16;

reg [7:0] S [0:15];
reg [8:0] symbol_counter;
integer i;

genvar gi;
generate
    for (gi = 0; gi < NSYM; gi = gi + 1) begin : PACK_SYNDROMES
        assign syndromes[8*gi +: 8] = S[gi];
    end
endgenerate

function [7:0] gf_mult;
    input [7:0] a;
    input [7:0] b;
    reg [15:0] aa;
    reg [7:0]  bb;
    reg [15:0] p;
    integer k;
    begin
        aa = {8'h00, a};
        bb = b;
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

function [7:0] gf_alpha_pow;
    input integer power;
    reg [7:0] result;
    integer k;
    begin
        result = 8'h01;
        for (k = 0; k < (power % 255); k = k + 1)
            result = gf_mult(result, 8'h02);
        gf_alpha_pow = result;
    end
endfunction

always @(posedge clk or negedge reset) begin
    if (!reset) begin
        symbol_counter  <= 9'd0;
        syndromes_ready <= 1'b0;
        for (i = 0; i < NSYM; i = i + 1)
            S[i] <= 8'h00;
    end else begin
        syndromes_ready <= 1'b0;

        if (enable) begin
            if (symbol_counter == 9'd0) begin
                for (i = 0; i < NSYM; i = i + 1)
                    S[i] <= received_symbol;
            end else begin
                for (i = 0; i < NSYM; i = i + 1)
                    S[i] <= gf_mult(S[i], gf_alpha_pow(i + 1)) ^ received_symbol;
            end

            if (symbol_counter == N-1) begin
                symbol_counter  <= 9'd0;
                syndromes_ready <= 1'b1;
            end else begin
                symbol_counter <= symbol_counter + 1'b1;
            end
        end
    end
end

endmodule