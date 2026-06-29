`timescale 1ns / 1ps
// =============================================================================
// pipeline_mem.v  —  Codeword Pipelining Memory
//
// A simple 255 x 8-bit synchronous dual-port RAM.
//
//  Write port (Port A):
//    Clocked on rising edge.  Used during the RECEIVE phase to store each
//    incoming codeword byte.
//
//  Read/Write port (Port B):
//    Clocked on rising edge.
//    Read  : used by the OUTPUT STAGE to fetch (corrected) codeword bytes.
//    Write : used by the CHIEN SEARCH to apply corrections in-place;
//            the correction byte is XOR'd with the stored value, so the
//            output stage simply reads out the already-corrected data.
//
// Note: write-before-read ordering on Port B for the correction write.
// =============================================================================
module pipeline_mem #(
    parameter N       = 255,   // codeword length
    parameter AW      = 8      // address width (ceil(log2(N)))
)(
    input  wire         clk,

    // ---- Port A : codeword write during RECEIVE ----
    input  wire         wr_a_en,
    input  wire [AW-1:0] wr_a_addr,
    input  wire [7:0]    wr_a_data,

    // ---- Port B : correction write during CHIEN, read during OUTPUT ----
    input  wire          wr_b_en,
    input  wire [AW-1:0] wr_b_addr,
    input  wire [7:0]    wr_b_data,   // XOR mask (error correction value)

    input  wire          rd_b_en,
    input  wire [AW-1:0] rd_b_addr,
    output reg  [7:0]    rd_b_data
);

    // -------------------------------------------------------------------------
    // 255 x 8-bit memory array
    // -------------------------------------------------------------------------
    reg [7:0] mem [0:N-1];

    // ---- Port A write ----
    integer ia;
    always @(posedge clk) begin
        if (wr_a_en) mem[wr_a_addr] <= wr_a_data;
    end

    // ---- Port B write (XOR correction) ----
    always @(posedge clk) begin
        if (wr_b_en) mem[wr_b_addr] <= mem[wr_b_addr] ^ wr_b_data;
    end

    // ---- Port B read (synchronous) ----
    always @(posedge clk) begin
        if (rd_b_en) rd_b_data <= mem[rd_b_addr];
    end

    // ---- Initialise memory to zero (simulation convenience) ----
    integer init_i;
    initial begin
        for (init_i = 0; init_i < N; init_i = init_i + 1)
            mem[init_i] = 8'h00;
        rd_b_data = 8'h00;
    end

endmodule
