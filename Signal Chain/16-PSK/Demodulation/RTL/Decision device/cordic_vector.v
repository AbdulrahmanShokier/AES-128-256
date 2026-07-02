module cordic_vector
(
    input  wire               clk,
    input  wire               rst,

    input  wire signed [15:0] x_in,
    input  wire signed [15:0] y_in,

    output reg  [15:0] angle
);

//////////////////////////////////////////////////////////////
// atan LUT
//
// Angle representation:
//
// 0      = 0°
//// 16384  = 90°
//// 32768  = 180°
//// 49152  = 270°
//// 65536  = 360°
//////////////////////////////////////////////////////////////

localparam [15:0] ATAN0 = 16'd8192;   // atan(1)
localparam [15:0] ATAN1 = 16'd4836;   // atan(1/2)
localparam [15:0] ATAN2 = 16'd2555;   // atan(1/4)
localparam [15:0] ATAN3 = 16'd1297;   // atan(1/8)
localparam [15:0] ATAN4 = 16'd651;    // atan(1/16)
localparam [15:0] ATAN5 = 16'd326;    // atan(1/32)
localparam [15:0] ATAN6 = 16'd163;    // atan(1/64)
localparam [15:0] ATAN7 = 16'd81;     // atan(1/128)

//////////////////////////////////////////////////////////////
// Stage 1 Registers
//////////////////////////////////////////////////////////////

reg signed [15:0] x1;
reg signed [15:0] y1;
reg signed [15:0] z1;

//////////////////////////////////////////////////////////////
// Stage 2 Registers
//////////////////////////////////////////////////////////////

reg signed [15:0] x2;
reg signed [15:0] y2;
reg signed [15:0] z2;

//////////////////////////////////////////////////////////////
// Stage 3 Registers
//////////////////////////////////////////////////////////////

reg signed [15:0] x3;
reg signed [15:0] y3;
reg signed [15:0] z3;

//////////////////////////////////////////////////////////////
// Stage 4 Registers
//////////////////////////////////////////////////////////////

reg signed [15:0] x4;
reg signed [15:0] y4;
reg signed [15:0] z4;

//////////////////////////////////////////////////////////////
// Internal wires
//////////////////////////////////////////////////////////////

reg signed [15:0] x_tmp;
reg signed [15:0] y_tmp;
reg signed [15:0] z_tmp;

reg signed [15:0] x_next;
reg signed [15:0] y_next;
reg signed [15:0] z_next;

//////////////////////////////////////////////////////////////
// CORDIC Pipeline Logic
//////////////////////////////////////////////////////////////

always @(posedge clk ) begin
    if (rst) begin
        x1    <= 16'sd0;
        y1    <= 16'sd0;
        z1    <= 16'sd0;
        x2    <= 16'sd0;
        y2    <= 16'sd0;
        z2    <= 16'sd0;
        x3    <= 16'sd0;
        y3    <= 16'sd0;
        z3    <= 16'sd0;
        x4    <= 16'sd0;
        y4    <= 16'sd0;
        z4    <= 16'sd0;
        angle <= 16'd0;
    end else begin
        
        // --- STAGE 1: Quadrant Correction & Iterations 0, 1 ---
        if (x_in < 0) begin
            x_tmp = -x_in;
            y_tmp = -y_in;
            z_tmp = 16'sd32768; // Pre-rotate 180 degrees
        end else begin
            x_tmp = x_in;
            y_tmp = y_in;
            z_tmp = 16'sd0;
        end

        // Iteration 0 (shift 0)
        if (y_tmp >= 0) begin
            x_next = x_tmp + y_tmp;
            y_next = y_tmp - x_tmp;
            z_next = z_tmp + ATAN0;
        end else begin
            x_next = x_tmp - y_tmp;
            y_next = y_tmp + x_tmp;
            z_next = z_tmp - ATAN0;
        end

        // Iteration 1 (shift 1)
        if (y_next >= 0) begin
            x1 <= x_next + (y_next >>> 1);
            y1 <= y_next - (x_next >>> 1);
            z1 <= z_next + ATAN1;
        end else begin
            x1 <= x_next - (y_next >>> 1);
            y1 <= y_next + (x_next >>> 1);
            z1 <= z_next - ATAN1;
        end

        // --- STAGE 2: Iterations 2, 3 ---
        x_tmp = x1;
        y_tmp = y1;
        z_tmp = z1;

        // Iteration 2 (shift 2)
        if (y_tmp >= 0) begin
            x_next = x_tmp + (y_tmp >>> 2);
            y_next = y_tmp - (x_tmp >>> 2);
            z_next = z_tmp + ATAN2;
        end else begin
            x_next = x_tmp - (y_tmp >>> 2);
            y_next = y_tmp + (x_tmp >>> 2);
            z_next = z_tmp - ATAN2;
        end

        // Iteration 3 (shift 3)
        if (y_next >= 0) begin
            x2 <= x_next + (y_next >>> 3);
            y2 <= y_next - (x_next >>> 3);
            z2 <= z_next + ATAN3;
        end else begin
            x2 <= x_next - (y_next >>> 3);
            y2 <= y_next + (x_next >>> 3);
            z2 <= z_next - ATAN3;
        end

        // --- STAGE 3: Iterations 4, 5 ---
        x_tmp = x2;
        y_tmp = y2;
        z_tmp = z2;

        // Iteration 4 (shift 4)
        if (y_tmp >= 0) begin
            x_next = x_tmp + (y_tmp >>> 4);
            y_next = y_tmp - (x_tmp >>> 4);
            z_next = z_tmp + ATAN4;
        end else begin
            x_next = x_tmp - (y_tmp >>> 4);
            y_next = y_tmp + (x_tmp >>> 4);
            z_next = z_tmp - ATAN4;
        end

        // Iteration 5 (shift 5)
        if (y_next >= 0) begin
            x3 <= x_next + (y_next >>> 5);
            y3 <= y_next - (x_next >>> 5);
            z3 <= z_next + ATAN5;
        end else begin
            x3 <= x_next - (y_next >>> 5);
            y3 <= y_next + (x_next >>> 5);
            z3 <= z_next - ATAN5;
        end

        // --- STAGE 4: Iterations 6, 7 ---
        x_tmp = x3;
        y_tmp = y3;
        z_tmp = z3;

        // Iteration 6 (shift 6)
        if (y_tmp >= 0) begin
            x_next = x_tmp + (y_tmp >>> 6);
            y_next = y_tmp - (x_tmp >>> 6);
            z_next = z_tmp + ATAN6;
        end else begin
            x_next = x_tmp - (y_tmp >>> 6);
            y_next = y_tmp + (x_tmp >>> 6);
            z_next = z_tmp - ATAN6;
        end

        // Iteration 7 (shift 7)
        if (y_next >= 0) begin
            x4 <= x_next + (y_next >>> 7);
            y4 <= y_next - (x_next >>> 7);
            z4 <= z_next + ATAN7;
        end else begin
            x4 <= x_next - (y_next >>> 7);
            y4 <= y_next + (x_next >>> 7);
            z4 <= z_next - ATAN7;
        end

        // Output assignment
        angle <= z4;
    end
end

endmodule