`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// Forney + correction + output block for RS(208,192).
// Stores the received 208-symbol frame, receives error positions from Chien,
// computes error magnitudes using Forney, corrects the stored frame, then outputs
// the first 192 corrected data symbols.
//
// CONSTANT-LATENCY MODIFICATION:
// The correction phase always consumes exactly T=8 correction slots.
// If fewer than 8 errors are detected, the remaining slots are idle padding.
// Therefore every correctable frame has the same timing as the worst-case
// 8-error frame.
// reset is active-low.
// -----------------------------------------------------------------------------
module Forney_Algorithm (
    input              clk,
    input              reset,

    input              proc_en,
    input              rec_en,
    input      [7:0]   Rx,

    input              chien_start,
    input              error_found_en,
    input      [7:0]   Xi,
    input      [7:0]   alpha_power,
    input              chien_done,
    input      [5:0]   num_errors,
    input              bm_uncorrectable,

    input      [127:0] syndromes,
    input      [71:0]  lambda,

    output reg         out_valid,
    output reg [7:0]   Cx,
    output reg         decode_fail,
    output reg         frame_done,
    output reg         output_symbol_tick
);

parameter N    = 208;
parameter K    = 192;
parameter NSYM = 16;
parameter T    = 8;
parameter OUTPUT_TICK_DIV = 4; // kept for documentation; GitHub-style output tick uses 2-bit symbol counter

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
reg [1:0] out_symbol_cnt;
reg       output_started;
reg [1:0] output_start_delay;
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

always @(posedge clk) begin
    if (!reset) begin
        rec_ctr          <= 9'd0;
        stored_err_count <= 6'd0;
        corr_idx         <= 6'd0;
        out_ctr          <= 9'd0;
        out_symbol_cnt   <= 2'd0;
        output_started   <= 1'b0;
        output_start_delay <= 2'd0;
        state            <= WAIT_CHIEN;
        out_valid        <= 1'b0;
        Cx               <= 8'h00;
        decode_fail      <= 1'b0;
        frame_done       <= 1'b0;
        output_symbol_tick <= 1'b0;
    end else begin
        // output_symbol_tick and frame_done are one-clock strobes.
        frame_done <= 1'b0;
        output_symbol_tick <= 1'b0;

        // DONE/out_valid is high during the active output phase.
        // The byte becomes READABLE only when output_symbol_tick=1.
        out_valid <= (state == OUTPUT) && output_started;

        // OUTPUT is handled outside proc_en because output_symbol_tick must be
        // delayed to the 4th main clock of each output-byte window, not asserted
        // on the first clock where Cx appears.
        if (state == OUTPUT) begin
            if (!output_started && (output_start_delay < (OUTPUT_TICK_DIV-1))) begin
                // Keep the 888-cycle DONE/Cx alignment.
                // During these alignment clocks, no output byte is visible.
                output_start_delay <= output_start_delay + 1'b1;
                out_valid <= 1'b0;
            end else begin
                // DONE/out_valid means Cx already contains the current output byte.
                // output_symbol_tick is the read/accept strobe on the 4th clock
                // of this byte window.
                out_valid <= 1'b1;

                if (!output_started) begin
                    // First clock of the output-byte window:
                    // DONE rises and Cx becomes the first byte (68).
                    // Do NOT assert output_symbol_tick yet.
                    Cx               <= received[out_ctr];
                    output_started   <= 1'b1;
                    out_symbol_cnt   <= 2'd1;
                end else if (out_symbol_cnt == (OUTPUT_TICK_DIV-1)) begin
                    // 4th clock of the same output-byte window:
                    // assert the read strobe while Cx is still holding this byte.
                    output_symbol_tick <= 1'b1;
                    out_symbol_cnt     <= 2'd0;

                    if (out_ctr == K-1) begin
                        state <= DONE_STATE;
                    end else begin
                        out_ctr <= out_ctr + 1'b1;
                    end
                end else if (out_symbol_cnt == 2'd0) begin
                    // Start the next output-byte window after the previous read tick.
                    // Cx becomes the next byte; output_symbol_tick stays low until
                    // the 4th clock of this new byte window.
                    Cx             <= received[out_ctr];
                    out_symbol_cnt <= 2'd1;
                end else begin
                    // Still inside the same 4-clock output-byte window.
                    out_symbol_cnt <= out_symbol_cnt + 1'b1;
                end
            end
        end

        // DONE_STATE is handled outside proc_en too, so the block returns ready
        // immediately after the final output read strobe, without waiting for
        // another 4-clock decoder_step_tick.
        if (state == DONE_STATE) begin
            frame_done     <= 1'b1;
            output_started <= 1'b0;
            output_start_delay <= 2'd0;
            out_valid      <= 1'b0;
            out_ctr        <= 9'd0;
            out_symbol_cnt <= 2'd0;
            corr_idx       <= 6'd0;
            state          <= WAIT_CHIEN;
        end

        if (rec_en) begin
            // A new frame can start without resetting the whole RS block.
            // On the first accepted byte, clear only the per-frame status.
            if (rec_ctr == 9'd0) begin
                stored_err_count <= 6'd0;
                corr_idx         <= 6'd0;
                out_ctr          <= 9'd0;
                out_symbol_cnt   <= 2'd0;
                output_started   <= 1'b0;
                output_start_delay <= 2'd0;
                decode_fail      <= 1'b0;
                frame_done       <= 1'b0;
            end

            received[rec_ctr] <= Rx;
            if (rec_ctr == N-1)
                rec_ctr <= 9'd0;
            else
                rec_ctr <= rec_ctr + 1'b1;
        end

        if (proc_en) begin
            if (chien_start) begin
                stored_err_count <= 6'd0;
                corr_idx         <= 6'd0;
                out_ctr          <= 9'd0;
                out_symbol_cnt   <= 2'd0;
                output_started   <= 1'b0;
                output_start_delay <= 2'd0;
                decode_fail      <= 1'b0;
                frame_done       <= 1'b0;
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

                    // If BM reports degree > T, or if Chien result count does not
                    // match the BM count, the frame is flagged as uncorrectable.
                    // The output timing is still kept constant.
                    if (bm_uncorrectable || (stored_err_count != num_errors) || (num_errors > T))
                        decode_fail <= 1'b1;

                    // Always enter the fixed-length correction phase.
                    // The phase lasts exactly T correction slots for every frame.
                    state <= CORRECT;
                end
            end

            CORRECT: begin
                if (corr_idx < T) begin
                    // For correctable frames, apply a real correction only for
                    // the detected error slots. For the remaining slots, do
                    // nothing. This padding makes the total timing fixed at the
                    // 8-error worst-case timing.
                    if ((!decode_fail) && (corr_idx < stored_err_count)) begin
                        err_value = gf_mult(
                            omega_eval(Err_Root[corr_idx]),
                            gf_inverse(lambda_derivative_eval(Err_Root[corr_idx]))
                        );

                        received[Err_Pos[corr_idx]] <= received[Err_Pos[corr_idx]] ^ err_value;
                    end

                    corr_idx <= corr_idx + 1'b1;
                end else begin
                    out_ctr <= 9'd0;
                    out_symbol_cnt <= 2'd0;
                    output_start_delay <= 2'd0;
                    state   <= OUTPUT;
                end
            end

            OUTPUT: begin
                // OUTPUT timing is handled in the main-clock section above.
                // This keeps the read strobe on the 4th main clock of the
                // output-byte window instead of on the first clock.
            end

            DONE_STATE: begin
                // DONE_STATE is handled in the main-clock section above.
            end

            default: begin
                state <= WAIT_CHIEN;
            end
            endcase
        end
    end
end

endmodule
