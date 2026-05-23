`timescale 1ns / 1ps
module chien_search #(
    parameter N  = 255,
    parameter T  = 16,
    parameter T2 = 32
)(
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,
    input  wire [255:0] syn_in,
    input  wire [127:0] lambda,
    input  wire [4:0]   err_count,
    output reg  [7:0]   err_pos,
    output reg  [7:0]   err_val,
    output reg          err_valid,
    output reg          decode_fail,
    output reg          done
);

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

    function [7:0] gf_inv_f;
        input [7:0] a;
        reg   [7:0] a2,a4,a8,a16,a32,a64,a128,t;
        begin
            a2  =gf_mul(a,  a); a4  =gf_mul(a2, a2);
            a8  =gf_mul(a4, a4);  a16 =gf_mul(a8, a8);
            a32 =gf_mul(a16,a16); a64 =gf_mul(a32,a32);
            a128=gf_mul(a64,a64);
            t=gf_mul(a2,a4); t=gf_mul(t,a8);  t=gf_mul(t,a16);
            t=gf_mul(t,a32); t=gf_mul(t,a64); gf_inv_f=gf_mul(t,a128);
        end
    endfunction

    function [7:0] get_lam;
        input integer k;
        begin
            if (k == 0) get_lam = 8'h01;
            else        get_lam = lambda[(k-1)*8 +: 8];
        end
    endfunction

    function [7:0] get_syn;
        input integer m;
        begin
            if (m < 1 || m > T2) get_syn = 8'h00;
            else                  get_syn = syn_in[(m-1)*8 +: 8];
        end
    endfunction

    function [7:0] alpha_k;
        input integer k;
        begin
            case (k)
                0:  alpha_k=8'h01; 1:  alpha_k=8'h02;  2:  alpha_k=8'h04;
                3:  alpha_k=8'h08; 4:  alpha_k=8'h10;  5:  alpha_k=8'h20;
                6:  alpha_k=8'h40; 7:  alpha_k=8'h80;  8:  alpha_k=8'h1D;
                9:  alpha_k=8'h3A; 10: alpha_k=8'h74;  11: alpha_k=8'hE8;
                12: alpha_k=8'hCD; 13: alpha_k=8'h87;  14: alpha_k=8'h13;
                15: alpha_k=8'h26; 16: alpha_k=8'h4C;  17: alpha_k=8'h98;
                18: alpha_k=8'h2D; 19: alpha_k=8'h5A;  20: alpha_k=8'hB4;
                21: alpha_k=8'h75; 22: alpha_k=8'hEA;  23: alpha_k=8'hC9;
                24: alpha_k=8'h8F; 25: alpha_k=8'h03;  26: alpha_k=8'h06;
                27: alpha_k=8'h0C; 28: alpha_k=8'h18;  29: alpha_k=8'h30;
                30: alpha_k=8'h60; 31: alpha_k=8'hC0;
                default: alpha_k=8'h01;
            endcase
        end
    endfunction

    function [7:0] phi_alpha;
        input integer j;
        begin
            case (j)
                0: phi_alpha=8'h01; 1: phi_alpha=8'h04;
                2: phi_alpha=8'h10; 3: phi_alpha=8'h40;
                4: phi_alpha=8'h1D; 5: phi_alpha=8'h74;
                6: phi_alpha=8'hCD; 7: phi_alpha=8'h13;
                default: phi_alpha=8'h01;
            endcase
        end
    endfunction

    reg [7:0] lambda_r [1:16];
    reg [7:0] omega_r  [0:31];
    reg [7:0] phi_r    [0:7];
    reg [7:0] omega_coeff [0:31];

    integer   oc_i, oc_j, oc_syn_idx;
    reg [7:0] oc_acc;

    reg [7:0] cs_lam_sum, cs_phi_sum, cs_omg_sum, cs_emag, cs_pos;
    reg       cs_is_root;
    integer   cs_j, init_i;
    reg [7:0] step_cnt;
    reg       running;
    reg [4:0] roots_cnt;
    
    // Forney Multiplier
    reg [7:0] Xk_reg; 

    always @(*) begin
        for (oc_i = 0; oc_i < T2; oc_i = oc_i + 1) begin
            oc_acc = 8'h00;
            for (oc_j = 0; oc_j <= T && oc_j <= oc_i; oc_j = oc_j + 1) begin
                oc_syn_idx = oc_i - oc_j + 1;
                oc_acc = oc_acc ^ gf_mul(get_lam(oc_j), get_syn(oc_syn_idx));
            end
            omega_coeff[oc_i] = oc_acc;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            running     <= 1'b0;  done        <= 1'b0;
            err_valid   <= 1'b0;  decode_fail <= 1'b0;
            roots_cnt   <= 5'd0;  step_cnt    <= 8'd0;
            Xk_reg      <= 8'h01; // Initialize Xk
            for (init_i = 1; init_i <= 16; init_i = init_i + 1) lambda_r[init_i] <= 8'h00;
            for (init_i = 0; init_i < 32; init_i = init_i + 1)  omega_r[init_i]  <= 8'h00;
            for (init_i = 0; init_i < 8;  init_i = init_i + 1)  phi_r[init_i]    <= 8'h00;
        end else begin
            done <= 1'b0; err_valid <= 1'b0; decode_fail <= 1'b0;

            if (start) begin
                for (init_i = 1; init_i <= 16; init_i = init_i + 1)
                    lambda_r[init_i] <= lambda[(init_i-1)*8 +: 8];
                for (init_i = 0; init_i < 32; init_i = init_i + 1)
                    omega_r[init_i]  <= omega_coeff[init_i];
                    
                phi_r[0] <= lambda[0 +: 8];   phi_r[1] <= lambda[16 +: 8];
                phi_r[2] <= lambda[32 +: 8];  phi_r[3] <= lambda[48 +: 8];
                phi_r[4] <= lambda[64 +: 8];  phi_r[5] <= lambda[80 +: 8];
                phi_r[6] <= lambda[96 +: 8];  phi_r[7] <= lambda[112 +: 8];
                
                step_cnt <= 8'd0; roots_cnt <= 5'd0; running <= 1'b1; Xk_reg <= 8'h01; // Reset Xk

            end else if (running) begin
                cs_lam_sum = 8'h01;
                for (cs_j = 1;  cs_j <= 16; cs_j = cs_j + 1) cs_lam_sum = cs_lam_sum ^ lambda_r[cs_j];

                cs_phi_sum = 8'h00;
                for (cs_j = 0; cs_j < 8;  cs_j = cs_j + 1) cs_phi_sum = cs_phi_sum ^ phi_r[cs_j];

                cs_omg_sum = 8'h00;
                for (cs_j = 0; cs_j < 32; cs_j = cs_j + 1) cs_omg_sum = cs_omg_sum ^ omega_r[cs_j];

                // Proper mapping without reversing
                cs_pos     = (step_cnt == 8'd0) ? 8'd254 : (step_cnt - 8'd1);
                cs_is_root = (cs_lam_sum == 8'h00) ? 1'b1 : 1'b0;

                if (cs_is_root) begin
                    cs_emag   = (cs_phi_sum != 8'h00) ? gf_mul(cs_omg_sum, gf_inv_f(cs_phi_sum)) : cs_omg_sum;
                    err_pos   <= cs_pos;
                    // Apply Forney multiplier
                    err_val   <= gf_mul(cs_emag, Xk_reg); 
                    err_valid <= 1'b1;
                    roots_cnt <= roots_cnt + 5'd1;
                end

                for (cs_j = 1;  cs_j <= 16; cs_j = cs_j + 1) lambda_r[cs_j] <= gf_mul(lambda_r[cs_j], alpha_k(cs_j));
                for (cs_j = 0; cs_j < 32; cs_j = cs_j + 1)   omega_r[cs_j]  <= gf_mul(omega_r[cs_j],  alpha_k(cs_j));
                for (cs_j = 0; cs_j < 8;  cs_j = cs_j + 1)   phi_r[cs_j]    <= gf_mul(phi_r[cs_j],    phi_alpha(cs_j));
                
                // Advance Xk
                Xk_reg <= gf_mul(Xk_reg, 8'h8E); 

                if (step_cnt == N - 1) begin
                    running <= 1'b0; done <= 1'b1;
                    if ((roots_cnt + (cs_is_root ? 5'd1 : 5'd0)) != err_count) decode_fail <= 1'b1;
                end
                step_cnt <= step_cnt + 8'd1;
            end
        end
    end
endmodule