`timescale 1ns / 1ps
// =============================================================================
// berlekamp_massey.v  —  RS(255,223) Berlekamp-Massey
//
// KEY FIX: replaced generate-block partial output assigns with a single
// concatenation assign for 'lambda'.
// Bit ordering: lambda[(k-1)*8 +: 8] = C[k]  for k=1..16
//   → lambda = {C[16], C[15], ..., C[1]}
// =============================================================================


//============================================================================
// Bberlekamp-Massey algorithm for RS(255,223) decoder. Computes the error locator polynomial
// from the input syndrome. The output 'lambda' is the error locator polynomial)
//============================================================================


module berlekamp_massey #(
    parameter T2 = 32
)(
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,
    input  wire [255:0] syn_in,
    output wire [127:0] lambda,
    output reg  [4:0]   err_count,
    output reg          done
);

    / ================================GF multiplication computational=========================================
    // gf_mul is the same as the gf_mult module in gf_arith.v
    // =======================================================================================================
    function [7:0] gf_mul;
        input [7:0] a, b;
        reg   [7:0] p, aa;
        integer     k;
        begin
            p = 8'h00; aa = a;
            for (k = 0; k < 8; k = k + 1) begin
                if (b[k]) p = p ^ aa;
                aa = aa[7] ? {aa[6:0],1'b0}^8'h1D : {aa[6:0],1'b0};
            end
            gf_mul = p;
        end
    endfunction

/ ================================GF inverse computational=========================================
    // gf_inv_f is the same as the gf_mult gf_inv module in gf_arith.v
    // =======================================================================================================
    function [7:0] gf_inv_f;
        input [7:0] a;
        reg   [7:0] a2,a4,a8,a16,a32,a64,a128,t;
        begin
            a2  =gf_mul(a,  a);   a4  =gf_mul(a2, a2);
            a8  =gf_mul(a4, a4);  a16 =gf_mul(a8, a8);
            a32 =gf_mul(a16,a16); a64 =gf_mul(a32,a32);
            a128=gf_mul(a64,a64);
            t=gf_mul(a2,a4); t=gf_mul(t,a8);  t=gf_mul(t,a16);
            t=gf_mul(t,a32); t=gf_mul(t,a64); gf_inv_f=gf_mul(t,a128);
        end
    endfunction

    // ================================Syndrome access function=========================================
    function [7:0] get_syn;
        input integer idx;
        begin
            get_syn = syn_in[idx*8 +: 8];
        end
    endfunction


    // =========================================================================
    // State registers
    // =========================================================================
    reg [7:0] C [0:16];
    reg [7:0] B [0:16];
    reg [4:0] Llen;
    reg [7:0] b_reg;
    reg [5:0] x_reg;
    reg [5:0] r_cnt;
    reg       running;

    // =========================================================================
    // Module-level temporaries
    // =========================================================================
    reg [7:0] disc_d;
    integer   disc_j;
    integer   disc_ridx;

    reg [7:0] bm_d;
    reg [7:0] bm_coeff;
    reg [7:0] bm_newC [0:16];
    integer   bm_j;
    integer   bm_shift;
    integer   init_i;

    // =========================================================================
    // Combinational discrepancy
    // =========================================================================
    always @(*) begin
        disc_d = get_syn(r_cnt);
        for (disc_j = 1; disc_j <= 16; disc_j = disc_j + 1) begin
            if (disc_j <= Llen) begin
                disc_ridx = r_cnt - disc_j;
                disc_d    = disc_d ^ gf_mul(C[disc_j], get_syn(disc_ridx));
            end
        end
    end

    // =========================================================================
    // BM sequential state machine
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            running   <= 1'b0; done      <= 1'b0;
            err_count <= 5'd0;
            for (init_i = 0; init_i <= 16; init_i = init_i + 1) begin
                C[init_i] <= 8'h00; B[init_i] <= 8'h00;
            end
            C[0]  <= 8'h01; B[0]  <= 8'h01;
            Llen  <= 5'd0;  b_reg <= 8'h01;
            x_reg <= 6'd1;  r_cnt <= 6'd0;
        end else begin
            done <= 1'b0;
            if (start) begin
                for (init_i = 0; init_i <= 16; init_i = init_i + 1) begin
                    C[init_i] <= 8'h00; B[init_i] <= 8'h00;
                end
                C[0]    <= 8'h01; B[0]    <= 8'h01;
                Llen    <= 5'd0;  b_reg   <= 8'h01;
                x_reg   <= 6'd1;  r_cnt   <= 6'd0;
                running <= 1'b1;
            end else if (running) begin
                bm_d     = disc_d;
                bm_coeff = gf_mul(bm_d, gf_inv_f(b_reg));
                for (bm_j = 0; bm_j <= 16; bm_j = bm_j + 1)
                    bm_newC[bm_j] = C[bm_j];
                if (bm_d != 8'h00) begin
                    for (bm_j = 0; bm_j <= 16; bm_j = bm_j + 1) begin
                        bm_shift = bm_j - x_reg;
                        if (bm_j >= x_reg && bm_shift <= 16)
                            bm_newC[bm_j] = C[bm_j] ^ gf_mul(bm_coeff, B[bm_shift]);
                    end
                    if ({Llen,1'b0} <= r_cnt) begin
                        for (bm_j = 0; bm_j <= 16; bm_j = bm_j + 1)
                            B[bm_j] <= C[bm_j];
                        Llen  <= r_cnt[4:0] + 5'd1 - Llen;
                        b_reg <= bm_d;
                        x_reg <= 6'd1;
                    end else
                        x_reg <= x_reg + 6'd1;
                end else
                    x_reg <= x_reg + 6'd1;
                for (bm_j = 0; bm_j <= 16; bm_j = bm_j + 1)
                    C[bm_j] <= bm_newC[bm_j];
                if (r_cnt == T2 - 1) begin
                    running   <= 1'b0; done      <= 1'b1;
                    err_count <= Llen;
                end
                r_cnt <= r_cnt + 6'd1;
            end
        end
    end

    // =========================================================================
    // Single assign output: avoids generate partial-assign elaboration issue
    // lambda[(k-1)*8 +: 8] = C[k]  →  lambda = {C[16], C[15], ..., C[1]}
    // =========================================================================
    assign lambda = { C[16], C[15], C[14], C[13], C[12], C[11], C[10], C[9],
                      C[8],  C[7],  C[6],  C[5],  C[4],  C[3],  C[2],  C[1] };

endmodule