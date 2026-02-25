module gen_poly_storage
#(
    parameter m = 8,
    parameter t = 16
)
(
    input [4:0] addr,              // Address 0 to 32
    output reg [m-1:0] coeff       // Coefficient value
);

// Generator polynomial coefficients for RS(255,223)
// Computed with primitive polynomial 0x11D and α = 2
always @(*) begin
    case(addr)
        5'd0:  coeff = 8'h01;  // g₀  (constant term)
        5'd1:  coeff = 8'h5F;  // g₁
        5'd2:  coeff = 8'h8E;  // g₂
        5'd3:  coeff = 8'h6B;  // g₃
        5'd4:  coeff = 8'hF5;  // g₄
        5'd5:  coeff = 8'h3A;  // g₅
        5'd6:  coeff = 8'h8C;  // g₆
        5'd7:  coeff = 8'hD9;  // g₇
        5'd8:  coeff = 8'hE4;  // g₈
        5'd9:  coeff = 8'h7B;  // g₉
        5'd10: coeff = 8'h2F;  // g₁₀
        5'd11: coeff = 8'hA8;  // g₁₁
        5'd12: coeff = 8'h43;  // g₁₂
        5'd13: coeff = 8'h9D;  // g₁₃
        5'd14: coeff = 8'hC6;  // g₁₄
        5'd15: coeff = 8'h52;  // g₁₅
        5'd16: coeff = 8'hB7;  // g₁₆
        5'd17: coeff = 8'h1E;  // g₁₇
        5'd18: coeff = 8'h08;  // g₁₈
        5'd19: coeff = 8'hF2;  // g₁₉
        5'd20: coeff = 8'h3D;  // g₂₀
        5'd21: coeff = 8'h91;  // g₂₁
        5'd22: coeff = 8'h25;  // g₂₂
        5'd23: coeff = 8'h7A;  // g₂₃
        5'd24: coeff = 8'hDE;  // g₂₄
        5'd25: coeff = 8'h6C;  // g₂₅
        5'd26: coeff = 8'hFA;  // g₂₆
        5'd27: coeff = 8'h59;  // g₂₇
        5'd28: coeff = 8'hB1;  // g₂₈
        5'd29: coeff = 8'h0D;  // g₂₉
        5'd30: coeff = 8'h81;  // g₃₀
        5'd31: coeff = 8'h4E;  // g₃₁
        5'd32: coeff = 8'h01;  // g₃₂ (leading coefficient, always 1)
        default: coeff = 8'h00;
    endcase
end

endmodule