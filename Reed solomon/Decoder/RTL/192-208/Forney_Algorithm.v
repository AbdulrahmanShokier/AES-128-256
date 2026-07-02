`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// Forney + correction + output block for RS(208,192).
// Stores the received 208-symbol frame, receives error positions from Chien,
// computes error magnitudes using Forney, corrects the stored frame, then outputs
// the first 192 corrected data symbols.
// reset is active-low.
// -----------------------------------------------------------------------------
module Forney_Algorithm (
    input              clk,
    input              reset,

    input              rec_en,
    input      [7:0]   Rx,

    input              chien_start,
    input              error_found_en,
    input      [7:0]   Xi,
    input      [7:0]   alpha_power,
    input              chien_done,
    input      [5:0]   num_errors,

    input      [127:0] syndromes,
    input      [71:0]  lambda,

    output reg         out_valid,
    output reg [7:0]   Cx,
    output reg         decode_fail
);

parameter N    = 208;
parameter K    = 192;
parameter NSYM = 16;
parameter T    = 8;

reg [7:0] received     [0:207];
reg [7:0] Err_Pos      [0:7];
reg [7:0] Err_Root     [0:7];
reg [7:0] Omega        [0:15];
reg [7:0] S_arr        [0:15];
reg [7:0] lambda_coeff [0:8];

reg [8:0] rec_ctr;
reg [5:0] stored_err_count;
reg [5:0] corr_idx;
reg [8:0] out_ctr;
reg [2:0] state;

integer i;
integer j;
integer k;
reg [7:0] err_value;

localparam WAIT_CHIEN = 3'd0;
localparam CORRECT    = 3'd1;
localparam OUTPUT     = 3'd2;
localparam DONE_STATE = 3'd3;

function [7:0] gf_mult;
    input [7:0] a;
    input [7:0] b;
    reg [15:0] aa;
    reg [7:0]  bb;
    reg [15:0] p;
    integer kk;
    begin
        aa = {8'h00, a};
        bb = b;
        p  = 16'h0000;
        for (kk = 0; kk < 8; kk = kk + 1) begin
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
    integer kk;
    begin
        result = 8'h01;
        for (kk = 0; kk < power; kk = kk + 1)
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

function [7:0] omega_eval;
    input [7:0] x;
    reg [7:0] acc;
    integer jj;
    begin
        acc = Omega[NSYM-1];
        for (jj = NSYM-2; jj >= 0; jj = jj - 1)
            acc = gf_mult(acc, x) ^ Omega[jj];
        omega_eval = acc;
    end
endfunction

function [7:0] lambda_derivative_eval;
    input [7:0] x;
    reg [7:0] acc;
    reg [7:0] xpow;
    integer jj;
    begin
        acc  = 8'h00;
        xpow = 8'h01;
        for (jj = 1; jj <= T; jj = jj + 1) begin
            if (jj[0])
                acc = acc ^ gf_mult(lambda_coeff[jj], xpow);
            xpow = gf_mult(xpow, x);
        end
        lambda_derivative_eval = acc;
    end
endfunction

always @(posedge clk or negedge reset) begin
    if (!reset) begin
        rec_ctr          <= 9'd0;
        stored_err_count <= 6'd0;
        corr_idx         <= 6'd0;
        out_ctr          <= 9'd0;
        state            <= WAIT_CHIEN;
        out_valid        <= 1'b0;
        Cx               <= 8'h00;
        decode_fail      <= 1'b0;
    end else begin
        out_valid <= 1'b0;

        if (rec_en) begin
            received[rec_ctr] <= Rx;
            if (rec_ctr == N-1)
                rec_ctr <= 9'd0;
            else
                rec_ctr <= rec_ctr + 1'b1;
        end

        if (chien_start) begin
            stored_err_count <= 6'd0;
            decode_fail      <= 1'b0;
            state            <= WAIT_CHIEN;
        end

        if (error_found_en) begin
            if (stored_err_count < T) begin
                Err_Pos[stored_err_count]  <= Xi;
                Err_Root[stored_err_count] <= alpha_power;
                stored_err_count <= stored_err_count + 1'b1;
            end else begin
                decode_fail <= 1'b1;
            end
        end

        case (state)
            WAIT_CHIEN: begin
                if (chien_done) begin
                    for (i = 0; i < NSYM; i = i + 1)
                        S_arr[i] <= syndromes[8*i +: 8];

                    for (i = 0; i <= T; i = i + 1)
                        lambda_coeff[i] <= lambda[8*i +: 8];

                    // Omega(x) = Syndrome(x) * Lambda(x) mod x^16
                    for (i = 0; i < NSYM; i = i + 1) begin
                        Omega[i] = 8'h00;
                        for (j = 0; j <= T; j = j + 1) begin
                            if (j <= i)
                                Omega[i] = Omega[i] ^ gf_mult(lambda[8*j +: 8], syndromes[8*(i-j) +: 8]);
                        end
                    end

                    corr_idx <= 6'd0;
                    out_ctr  <= 9'd0;

                    if (num_errors == 6'd0) begin
                        state <= OUTPUT;
                    end else if ((stored_err_count != num_errors) || (num_errors > T)) begin
                        decode_fail <= 1'b1;
                        state       <= OUTPUT;
                    end else begin
                        state <= CORRECT;
                    end
                end
            end

            CORRECT: begin
                if (corr_idx < stored_err_count) begin
                    err_value = gf_mult(
                        omega_eval(Err_Root[corr_idx]),
                        gf_inverse(lambda_derivative_eval(Err_Root[corr_idx]))
                    );

                    received[Err_Pos[corr_idx]] <= received[Err_Pos[corr_idx]] ^ err_value;
                    corr_idx <= corr_idx + 1'b1;
                end else begin
                    out_ctr <= 9'd0;
                    state   <= OUTPUT;
                end
            end

            OUTPUT: begin
                if (out_ctr < K) begin
                    Cx        <= received[out_ctr];
                    out_valid <= 1'b1;
                    out_ctr   <= out_ctr + 1'b1;
                end else begin
                    state <= DONE_STATE;
                end
            end

            DONE_STATE: begin
                state <= DONE_STATE;
            end

            default: begin
                state <= WAIT_CHIEN;
            end
        endcase
    end
end

endmodule