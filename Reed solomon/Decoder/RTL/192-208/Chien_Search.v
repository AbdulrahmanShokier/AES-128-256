`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// Chien search for RS(208,192).
// This is a shortened RS code over GF(2^8):
//   full-length reference = 255 symbols
//   actual N              = 208 symbols
//   shortening offset     = 255 - 208 = 47 symbols
//
// For symbol position p = 0..207, the Chien test uses:
//   Lambda(alpha^(p + 47 + 1)) = Lambda(alpha^(p + 48))
// If it is zero, that symbol position contains an error.
// reset is active-low.
// -----------------------------------------------------------------------------
module Chien_Search (
    input              clk,
    input              reset,
    input              start,
    input      [71:0]  lambda,
    input      [5:0]   L,
    output reg         error_found,
    output reg [7:0]   xi,
    output reg [7:0]   alpha_power,
    output reg [5:0]   error_count,
    output reg         done
);

parameter N       = 208;
parameter T       = 8;
parameter SHORTEN = 47;  // 255 - N

reg        scanning;
reg        done_pending;
reg [8:0]  scan_pos;
reg [7:0]  x_val;
integer i;

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

function [7:0] get_lambda;
    input integer idx;
    begin
        get_lambda = lambda[8*idx +: 8];
    end
endfunction

function [7:0] lambda_eval;
    input [7:0] x;
    reg [7:0] acc;
    integer j;
    begin
        acc = get_lambda(T);
        for (j = T-1; j >= 0; j = j - 1)
            acc = gf_mult(acc, x) ^ get_lambda(j);
        lambda_eval = acc;
    end
endfunction

always @(posedge clk or negedge reset) begin
    if (!reset) begin
        scanning     <= 1'b0;
        done_pending <= 1'b0;
        scan_pos     <= 9'd0;
        error_found  <= 1'b0;
        xi           <= 8'd0;
        alpha_power  <= 8'd0;
        error_count  <= 6'd0;
        done         <= 1'b0;
    end else begin
        error_found <= 1'b0;
        done        <= 1'b0;

        if (start) begin
            scanning     <= 1'b1;
            done_pending <= 1'b0;
            scan_pos     <= 9'd0;
            error_count  <= 6'd0;
        end else if (done_pending) begin
            done_pending <= 1'b0;
            done         <= 1'b1;
        end else if (scanning) begin
            x_val = gf_alpha_pow(scan_pos + SHORTEN + 1);

            if ((L != 6'd0) && (lambda_eval(x_val) == 8'h00)) begin
                error_found <= 1'b1;
                xi          <= scan_pos[7:0];
                alpha_power <= x_val;
                error_count <= error_count + 1'b1;
            end

            if (scan_pos == N-1) begin
                scanning     <= 1'b0;
                done_pending <= 1'b1;
            end else begin
                scan_pos <= scan_pos + 1'b1;
            end
        end
    end
end

endmodule
