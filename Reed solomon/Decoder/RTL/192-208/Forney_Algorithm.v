`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// Forney + correction + output block for RS(208,192).
//
// XST VIRTEX-6 SYNTHESIS FIXES APPLIED:
// - Brutal-force flattening of gf_mult (no loops).
// - Exponentiation by squaring for gf_inverse (no loops).
// - Brutal-force flattening of Omega convolution (no loops).
// - Distributed RAM inference fix for 'received' array read-modify-write.
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
parameter OUTPUT_TICK_DIV = 4; 

reg [7:0] received     [0:207];
reg [7:0] Err_Pos      [0:7];
reg [7:0] Err_Root     [0:7];
reg [7:0] Omega        [0:15];
reg [7:0] lambda_coeff [0:8];

reg [8:0] rec_ctr;
reg [5:0] stored_err_count;
reg [5:0] corr_idx;
reg [8:0] out_ctr;
reg [1:0] out_symbol_cnt;
reg       output_started;
reg [1:0] output_start_delay;
reg [2:0] state;

localparam WAIT_CHIEN = 3'd0;
localparam CORRECT    = 3'd1;
localparam OUTPUT     = 3'd2;
localparam DONE_STATE = 3'd3;

// --- XST FIX 1: PURE COMBINATORIAL MULTIPLIER (NO LOOPS) ---
function [7:0] gf_mult;
    input [7:0] a;
    input [7:0] b;
    reg [7:0] p;
    reg [7:0] aa;
    begin
        p = 8'h00;
        aa = a;
        if (b[0]) p = p ^ aa;
        aa = (aa[7]) ? ((aa << 1) ^ 8'h1D) : (aa << 1);
        if (b[1]) p = p ^ aa;
        aa = (aa[7]) ? ((aa << 1) ^ 8'h1D) : (aa << 1);
        if (b[2]) p = p ^ aa;
        aa = (aa[7]) ? ((aa << 1) ^ 8'h1D) : (aa << 1);
        if (b[3]) p = p ^ aa;
        aa = (aa[7]) ? ((aa << 1) ^ 8'h1D) : (aa << 1);
        if (b[4]) p = p ^ aa;
        aa = (aa[7]) ? ((aa << 1) ^ 8'h1D) : (aa << 1);
        if (b[5]) p = p ^ aa;
        aa = (aa[7]) ? ((aa << 1) ^ 8'h1D) : (aa << 1);
        if (b[6]) p = p ^ aa;
        aa = (aa[7]) ? ((aa << 1) ^ 8'h1D) : (aa << 1);
        if (b[7]) p = p ^ aa;
        gf_mult = p;
    end
endfunction

// --- XST FIX 2: EXPONENTIATION BY SQUARING ---
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

// --- XST FIX 3: EXPLICIT OMEGA CONVOLUTION ---
wire [7:0] s0 = syndromes[7:0];    wire [7:0] s8 = syndromes[71:64];
wire [7:0] s1 = syndromes[15:8];   wire [7:0] s9 = syndromes[79:72];
wire [7:0] s2 = syndromes[23:16];  wire [7:0] s10 = syndromes[87:80];
wire [7:0] s3 = syndromes[31:24];  wire [7:0] s11 = syndromes[95:88];
wire [7:0] s4 = syndromes[39:32];  wire [7:0] s12 = syndromes[103:96];
wire [7:0] s5 = syndromes[47:40];  wire [7:0] s13 = syndromes[111:104];
wire [7:0] s6 = syndromes[55:48];  wire [7:0] s14 = syndromes[119:112];
wire [7:0] s7 = syndromes[63:56];  wire [7:0] s15 = syndromes[127:120];

wire [7:0] l0 = lambda[7:0];       wire [7:0] l5 = lambda[47:40];
wire [7:0] l1 = lambda[15:8];      wire [7:0] l6 = lambda[55:48];
wire [7:0] l2 = lambda[23:16];     wire [7:0] l7 = lambda[63:56];
wire [7:0] l3 = lambda[31:24];     wire [7:0] l8 = lambda[71:64];
wire [7:0] l4 = lambda[39:32];

wire [7:0] nO_0 = gf_mult(l0, s0);
wire [7:0] nO_1 = gf_mult(l0, s1) ^ gf_mult(l1, s0);
wire [7:0] nO_2 = gf_mult(l0, s2) ^ gf_mult(l1, s1) ^ gf_mult(l2, s0);
wire [7:0] nO_3 = gf_mult(l0, s3) ^ gf_mult(l1, s2) ^ gf_mult(l2, s1) ^ gf_mult(l3, s0);
wire [7:0] nO_4 = gf_mult(l0, s4) ^ gf_mult(l1, s3) ^ gf_mult(l2, s2) ^ gf_mult(l3, s1) ^ gf_mult(l4, s0);
wire [7:0] nO_5 = gf_mult(l0, s5) ^ gf_mult(l1, s4) ^ gf_mult(l2, s3) ^ gf_mult(l3, s2) ^ gf_mult(l4, s1) ^ gf_mult(l5, s0);
wire [7:0] nO_6 = gf_mult(l0, s6) ^ gf_mult(l1, s5) ^ gf_mult(l2, s4) ^ gf_mult(l3, s3) ^ gf_mult(l4, s2) ^ gf_mult(l5, s1) ^ gf_mult(l6, s0);
wire [7:0] nO_7 = gf_mult(l0, s7) ^ gf_mult(l1, s6) ^ gf_mult(l2, s5) ^ gf_mult(l3, s4) ^ gf_mult(l4, s3) ^ gf_mult(l5, s2) ^ gf_mult(l6, s1) ^ gf_mult(l7, s0);
wire [7:0] nO_8 = gf_mult(l0, s8) ^ gf_mult(l1, s7) ^ gf_mult(l2, s6) ^ gf_mult(l3, s5) ^ gf_mult(l4, s4) ^ gf_mult(l5, s3) ^ gf_mult(l6, s2) ^ gf_mult(l7, s1) ^ gf_mult(l8, s0);
wire [7:0] nO_9 = gf_mult(l0, s9) ^ gf_mult(l1, s8) ^ gf_mult(l2, s7) ^ gf_mult(l3, s6) ^ gf_mult(l4, s5) ^ gf_mult(l5, s4) ^ gf_mult(l6, s3) ^ gf_mult(l7, s2) ^ gf_mult(l8, s1);
wire [7:0] nO_10 = gf_mult(l0, s10) ^ gf_mult(l1, s9) ^ gf_mult(l2, s8) ^ gf_mult(l3, s7) ^ gf_mult(l4, s6) ^ gf_mult(l5, s5) ^ gf_mult(l6, s4) ^ gf_mult(l7, s3) ^ gf_mult(l8, s2);
wire [7:0] nO_11 = gf_mult(l0, s11) ^ gf_mult(l1, s10) ^ gf_mult(l2, s9) ^ gf_mult(l3, s8) ^ gf_mult(l4, s7) ^ gf_mult(l5, s6) ^ gf_mult(l6, s5) ^ gf_mult(l7, s4) ^ gf_mult(l8, s3);
wire [7:0] nO_12 = gf_mult(l0, s12) ^ gf_mult(l1, s11) ^ gf_mult(l2, s10) ^ gf_mult(l3, s9) ^ gf_mult(l4, s8) ^ gf_mult(l5, s7) ^ gf_mult(l6, s6) ^ gf_mult(l7, s5) ^ gf_mult(l8, s4);
wire [7:0] nO_13 = gf_mult(l0, s13) ^ gf_mult(l1, s12) ^ gf_mult(l2, s11) ^ gf_mult(l3, s10) ^ gf_mult(l4, s9) ^ gf_mult(l5, s8) ^ gf_mult(l6, s7) ^ gf_mult(l7, s6) ^ gf_mult(l8, s5);
wire [7:0] nO_14 = gf_mult(l0, s14) ^ gf_mult(l1, s13) ^ gf_mult(l2, s12) ^ gf_mult(l3, s11) ^ gf_mult(l4, s10) ^ gf_mult(l5, s9) ^ gf_mult(l6, s8) ^ gf_mult(l7, s7) ^ gf_mult(l8, s6);
wire [7:0] nO_15 = gf_mult(l0, s15) ^ gf_mult(l1, s14) ^ gf_mult(l2, s13) ^ gf_mult(l3, s12) ^ gf_mult(l4, s11) ^ gf_mult(l5, s10) ^ gf_mult(l6, s9) ^ gf_mult(l7, s8) ^ gf_mult(l8, s7);

// --- XST FIX 4: UNROLLED ERROR MAGNITUDE ---
wire [7:0] current_root = Err_Root[corr_idx];

wire [7:0] o14 = gf_mult(Omega[15], current_root) ^ Omega[14];
wire [7:0] o13 = gf_mult(o14, current_root) ^ Omega[13];
wire [7:0] o12 = gf_mult(o13, current_root) ^ Omega[12];
wire [7:0] o11 = gf_mult(o12, current_root) ^ Omega[11];
wire [7:0] o10 = gf_mult(o11, current_root) ^ Omega[10];
wire [7:0] o9  = gf_mult(o10, current_root) ^ Omega[9];
wire [7:0] o8  = gf_mult(o9,  current_root) ^ Omega[8];
wire [7:0] o7  = gf_mult(o8,  current_root) ^ Omega[7];
wire [7:0] o6  = gf_mult(o7,  current_root) ^ Omega[6];
wire [7:0] o5  = gf_mult(o6,  current_root) ^ Omega[5];
wire [7:0] o4  = gf_mult(o5,  current_root) ^ Omega[4];
wire [7:0] o3  = gf_mult(o4,  current_root) ^ Omega[3];
wire [7:0] o2  = gf_mult(o3,  current_root) ^ Omega[2];
wire [7:0] o1  = gf_mult(o2,  current_root) ^ Omega[1];
wire [7:0] current_omega_val = gf_mult(o1, current_root) ^ Omega[0];

wire [7:0] rt2 = gf_mult(current_root, current_root); 
wire [7:0] rt4 = gf_mult(rt2, rt2);                   
wire [7:0] rt6 = gf_mult(rt4, rt2);                   

wire [7:0] current_lambda_deriv_val = lambda_coeff[1] ^ 
                                      gf_mult(lambda_coeff[3], rt2) ^ 
                                      gf_mult(lambda_coeff[5], rt4) ^ 
                                      gf_mult(lambda_coeff[7], rt6);

wire [7:0] current_err_value = gf_mult(current_omega_val, gf_inverse(current_lambda_deriv_val));

// --- XST FIX 5: EXPLICIT RAM ADDRESSING ---
wire [7:0] target_pos     = Err_Pos[corr_idx];
wire [7:0] read_rx_byte   = received[target_pos];
wire [7:0] corrected_byte = read_rx_byte ^ current_err_value;

always @(posedge clk ) begin
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
        frame_done <= 1'b0;
        output_symbol_tick <= 1'b0;
        out_valid <= (state == OUTPUT) && output_started;

        if (state == OUTPUT) begin
            if (!output_started && (output_start_delay < (OUTPUT_TICK_DIV-1))) begin
                output_start_delay <= output_start_delay + 1'b1;
                out_valid <= 1'b0;
            end else begin
                out_valid <= 1'b1;
                if (!output_started) begin
                    Cx               <= received[out_ctr];
                    output_started   <= 1'b1;
                    out_symbol_cnt   <= 2'd1;
                end else if (out_symbol_cnt == (OUTPUT_TICK_DIV-1)) begin
                    output_symbol_tick <= 1'b1;
                    out_symbol_cnt     <= 2'd0;
                    if (out_ctr == K-1) state <= DONE_STATE;
                    else out_ctr <= out_ctr + 1'b1;
                end else if (out_symbol_cnt == 2'd0) begin
                    Cx             <= received[out_ctr];
                    out_symbol_cnt <= 2'd1;
                end else out_symbol_cnt <= out_symbol_cnt + 1'b1;
            end
        end

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
            if (rec_ctr == N-1) rec_ctr <= 9'd0;
            else rec_ctr <= rec_ctr + 1'b1;
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
                end else decode_fail <= 1'b1;
            end

            case (state)
            WAIT_CHIEN: begin
                if (chien_done) begin
                    lambda_coeff[0] <= l0; lambda_coeff[1] <= l1;
                    lambda_coeff[2] <= l2; lambda_coeff[3] <= l3;
                    lambda_coeff[4] <= l4; lambda_coeff[5] <= l5;
                    lambda_coeff[6] <= l6; lambda_coeff[7] <= l7;
                    lambda_coeff[8] <= l8;

                    Omega[0] <= nO_0; Omega[1] <= nO_1; Omega[2] <= nO_2;
                    Omega[3] <= nO_3; Omega[4] <= nO_4; Omega[5] <= nO_5;
                    Omega[6] <= nO_6; Omega[7] <= nO_7; Omega[8] <= nO_8;
                    Omega[9] <= nO_9; Omega[10] <= nO_10; Omega[11] <= nO_11;
                    Omega[12] <= nO_12; Omega[13] <= nO_13; Omega[14] <= nO_14;
                    Omega[15] <= nO_15;

                    corr_idx <= 6'd0;
                    out_ctr  <= 9'd0;

                    if (bm_uncorrectable || (stored_err_count != num_errors) || (num_errors > T))
                        decode_fail <= 1'b1;
                    
                    state <= CORRECT;
                end
            end

            CORRECT: begin
                if (corr_idx < T) begin
                    if ((!decode_fail) && (corr_idx < stored_err_count)) begin
                        // Using the isolated RAM targeting wires
                        received[target_pos] <= corrected_byte;
                    end
                    corr_idx <= corr_idx + 1'b1;
                end else begin
                    out_ctr <= 9'd0;
                    out_symbol_cnt <= 2'd0;
                    output_start_delay <= 2'd0;
                    state   <= OUTPUT;
                end
            end

            OUTPUT:     begin end
            DONE_STATE: begin end
            default:    state <= WAIT_CHIEN;
            endcase
        end
    end
end

endmodule