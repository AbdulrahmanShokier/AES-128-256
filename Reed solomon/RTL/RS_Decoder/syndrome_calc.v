`timescale 1ns / 1ps
// =============================================================================
// syndrome_calc.v  —  RS(255,223) Syndrome Calculator
//
// KEY FIX: replaced generate-block partial output assigns with a single
// concatenation assign.  QuestaSim 2021 elaborator can reject output wire
// ports driven by multiple partial assigns from a generate loop.
//
// syn_out[j*8 +: 8] = S[j]  for j=0..31 thus Starting at bit index j*8
// Mapping to concat: syn_out = {syn[31], syn[30], ..., syn[0]}
// =============================================================================
// =============================================================================
// METHOD CHOICE: Uses Method 1 (Direct Evaluation via Horner's Scheme).
// Processes data byte-by-byte on every valid clock(thus better than polynomail division
// which require storing the whole polynomial), evaluating the received 
// polynomial R(X) at roots alpha^i across 32 parallel channels.
// Preferred over Method 2 (Polynomial Division) for modern hardware because it
// enables high-throughput parallel processing with simple control logic.
// =============================================================================

module syndrome_calc #(
    parameter N   = 255,
    parameter T2  = 32
)(
    input  wire         clk,
    input  wire         rst_n,
    input  wire         clr,
    input  wire [7:0]   data_in,
    input  wire         data_valid,
    output wire [255:0] syn_out,
    output reg          done
);


    // ================================GF multiplication computational=========================================
    // gf_mul is the same as the gf_mult module in gf_arith.v
    // NOTE: This combinational function processes data on a byte-by-byte basis.
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


    //===============precomputed look-up table (LUT) of powers of alpha======================================
    function [7:0] alpha_pow;
        input [4:0] j; // 4 bits to index 32 syndromes
        begin
            case (j)
                5'd0:  alpha_pow=8'h02; 5'd1:  alpha_pow=8'h04;
                5'd2:  alpha_pow=8'h08; 5'd3:  alpha_pow=8'h10;
                5'd4:  alpha_pow=8'h20; 5'd5:  alpha_pow=8'h40;
                5'd6:  alpha_pow=8'h80; 5'd7:  alpha_pow=8'h1D;
                5'd8:  alpha_pow=8'h3A; 5'd9:  alpha_pow=8'h74;
                5'd10: alpha_pow=8'hE8; 5'd11: alpha_pow=8'hCD;
                5'd12: alpha_pow=8'h87; 5'd13: alpha_pow=8'h13;
                5'd14: alpha_pow=8'h26; 5'd15: alpha_pow=8'h4C;
                5'd16: alpha_pow=8'h98; 5'd17: alpha_pow=8'h2D;
                5'd18: alpha_pow=8'h5A; 5'd19: alpha_pow=8'hB4;
                5'd20: alpha_pow=8'h75; 5'd21: alpha_pow=8'hEA;
                5'd22: alpha_pow=8'hC9; 5'd23: alpha_pow=8'h8F;
                5'd24: alpha_pow=8'h03; 5'd25: alpha_pow=8'h06;
                5'd26: alpha_pow=8'h0C; 5'd27: alpha_pow=8'h18;
                5'd28: alpha_pow=8'h30; 5'd29: alpha_pow=8'h60;
                5'd30: alpha_pow=8'hC0; 5'd31: alpha_pow=8'h9D;
                default: alpha_pow=8'h01;
            endcase
        end
    endfunction

    reg [7:0] syn [0:31]; // syndrome registers S[0]..S[31], each 8 bits
    reg [7:0] cnt; // counts number of data bytes processed, max 255
    integer   i;


    // ==============================Syndrome Calculation===========================================
    // Syndrome_i = R(\alpha^i)
    // recivning polynomial R(X) = (r_{254}) * X^(254) + ... + r_1 * X + r_0
    // Horner's scheme: S[i] = ((...(r_{254} * alpha^i + r_{253}) * alpha^i + r_{252}) ... ) * alpha^i + r_0
    // It receives the highest-order coefficient first.
    // On each valid clock, shift the current syndrome value left by multiplying with alpha^i,
    // then add the new data byte (the lowest-order coefficient r_0) to update the syndrome.
    // 
    // Example for S[1] (i=1):
    // Cycle 1 (First Byte Arrives: r_{254}):
    //      syn[1] starts at 8'h00
    //      gf_mul(0,alpha^1) XOR r_{254} = 0 XOR r_{254} = r_{254}
    //      Result: syn[1] stores r_{254}
    // Cycle 2 (Second Byte Arrives: r_{253}):
    //      syn[1] currently holds r_{254}.
    //      syn[1] = gf_mul(r_{254}, alpha^1) XOR r_{253}
    //      Result: syn[1] stores r_{254} * alpha^1 + r_{253}
    // Cycle 3 (Third Byte Arrives: r_{252}):
    //      syn[1] currently holds r_{254} * alpha^1 + r_{253}.
    //      syn[1] = gf_mul(syn[1], alpha^1) XOR r_{252}
    //      Result: syn[1] stores r_{254} * alpha^2 + r_{253} * alpha^1 + r_{252}
    //and so on, until Cycle 255 (Last Byte Arrives: r_0):
    // ========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) syn[i] <= 8'h00;
            cnt  <= 8'd0;
            done <= 1'b0;
        end else begin
            done <= 1'b0;
            if (clr) begin
                for (i = 0; i < 32; i = i + 1) syn[i] <= 8'h00;
                cnt <= 8'd0;
            end else if (data_valid) begin
                for (i = 0; i < 32; i = i + 1)
                    syn[i] <= gf_mul(syn[i], alpha_pow(i[4:0])) ^ data_in;
                if (cnt == N - 1) begin
                    cnt  <= 8'd0;
                    done <= 1'b1;
                end else
                    cnt <= cnt + 8'd1;
            end
        end
    end



    // -------------------------------------------------------------------------
    // Single assign: avoids generate partial-assign elaboration issue
    // Bit ordering: syn_out[j*8+:8] = syn[j]
    //   → syn_out = {syn[31], syn[30], ..., syn[0]}
    // -------------------------------------------------------------------------
    assign syn_out = { syn[31], syn[30], syn[29], syn[28],
                       syn[27], syn[26], syn[25], syn[24],
                       syn[23], syn[22], syn[21], syn[20],
                       syn[19], syn[18], syn[17], syn[16],
                       syn[15], syn[14], syn[13], syn[12],
                       syn[11], syn[10], syn[9],  syn[8],
                       syn[7],  syn[6],  syn[5],  syn[4],
                       syn[3],  syn[2],  syn[1],  syn[0]  };

endmodule