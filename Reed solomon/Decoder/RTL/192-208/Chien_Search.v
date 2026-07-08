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
//
// XST FIX APPLIED:
// - Removed dynamic alpha-power loop with variable loop limit.
// - Replaced it with a running alpha register starting at alpha^48.
// - Replaced dynamic lambda part-select with a case-based accessor.
// - Rewrote lambda_eval loop with a fixed forward loop.
// -----------------------------------------------------------------------------
module Chien_Search (
    input              clk,
    input              reset,
    input              clk_en,
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

// alpha^(SHORTEN+1) = alpha^48 for GF(2^8), primitive polynomial 0x11D.
localparam [7:0] ALPHA_START = 8'h46;
localparam [7:0] ALPHA       = 8'h02;

reg        scanning;
reg        done_pending;
reg [8:0]  scan_pos;
reg [7:0]  x_current;
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

function [7:0] get_lambda;
    input integer idx;
    begin
        case (idx)
            0: get_lambda = lambda[7:0];
            1: get_lambda = lambda[15:8];
            2: get_lambda = lambda[23:16];
            3: get_lambda = lambda[31:24];
            4: get_lambda = lambda[39:32];
            5: get_lambda = lambda[47:40];
            6: get_lambda = lambda[55:48];
            7: get_lambda = lambda[63:56];
            8: get_lambda = lambda[71:64];
            default: get_lambda = 8'h00;
        endcase
    end
endfunction

function [7:0] lambda_eval;
    input [7:0] x;
    reg [7:0] acc;
    integer j;
    begin
        acc = get_lambda(T);
        // Fixed 8-step Horner evaluation.
        for (j = 0; j < T; j = j + 1) begin
            acc = gf_mult(acc, x) ^ get_lambda(T - 1 - j);
        end
        lambda_eval = acc;
    end
endfunction

always @(posedge clk) begin
    if (!reset) begin
        scanning     <= 1'b0;
        done_pending <= 1'b0;
        scan_pos     <= 9'd0;
        x_current    <= ALPHA_START;
        x_val        <= 8'd0;
        error_found  <= 1'b0;
        xi           <= 8'd0;
        alpha_power  <= 8'd0;
        error_count  <= 6'd0;
        done         <= 1'b0;
    end else begin
        if (clk_en) begin
            error_found <= 1'b0;
            done        <= 1'b0;

            if (start) begin
                scanning     <= 1'b1;
                done_pending <= 1'b0;
                scan_pos     <= 9'd0;
                error_count  <= 6'd0;
                x_current    <= ALPHA_START;
            end else if (done_pending) begin
                done_pending <= 1'b0;
                done         <= 1'b1;
            end else if (scanning) begin
                x_val = x_current;

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
                    scan_pos  <= scan_pos + 1'b1;
                    x_current <= gf_mult(x_current, ALPHA);
                end
            end
        end
    end
end

endmodule
