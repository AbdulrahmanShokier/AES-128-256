module rs_mod_reg #(
    parameter IN_WIDTH     = 8,
    parameter REG_WIDTH    = 128,
    parameter OUT_WIDTH    = 4,
    parameter BYTE_COUNT_W = 4,   // 0-15
    parameter NIB_COUNT_W  = 5,    // 0-31
    parameter CYC_COUNT_W  = 5
)
(
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   symbol_tick,

    input  wire                   wr_en,       // outer FSM: RS has a byte ready
    input  wire [IN_WIDTH-1:0]    data_in,

    input  wire [CYC_COUNT_W-1:0] cyc,

    output reg  [OUT_WIDTH-1:0]   data_out    // free-running nibble out, every symbol_tick

//    output reg                    swap         // pulses high for 1 symbol_tick when fill buffer completes
);

reg [REG_WIDTH-1:0]    buf_A;
//reg [REG_WIDTH-1:0]    buf_B;
reg [BYTE_COUNT_W-1:0] byte_cnt;
reg [NIB_COUNT_W-1:0]  nib_cnt;
//reg                    fill_sel;   // 0 = filling buf_A (draining buf_B)
                                    // 1 = filling buf_B (draining buf_A)

// ---- Fill side: byte in, gated by wr_en (RS can stall) ----
always @(posedge clk) begin
    if (symbol_tick && !rst) begin
        buf_A    <= {REG_WIDTH{1'b0}};
//        buf_B    <= {REG_WIDTH{1'b0}};
        byte_cnt <= {BYTE_COUNT_W{1'b0}};
    end
    else if (symbol_tick && wr_en) begin
//        if (!fill_sel)
            buf_A[byte_cnt*IN_WIDTH +: IN_WIDTH] <= data_in;
//        else
//            buf_B[byte_cnt*IN_WIDTH +: IN_WIDTH] <= data_in;
       byte_cnt <= byte_cnt + 1'b1;   // wraps 15->0
    end
end

// ---- Swap pulse + role select: triggered by byte_cnt completing its 16th write ----
// always @(posedge clk) begin
//     if (!rst) begin
//         fill_sel <= 1'b0;
//         swap     <= 1'b0;
//     end
//     else if (symbol_tick) begin
//         if (wr_en && byte_cnt == {BYTE_COUNT_W{1'b1}}) begin  // this tick writes the 16th byte
//             fill_sel <= ~fill_sel;
//             swap     <= 1'b1;    // 1-symbol_tick pulse, visible to outer FSM
//         end
//         else begin
//             swap     <= 1'b0;
//         end
//     end
// end

// ---- Drain side: nibble out, free-running every symbol_tick, never stalls ----
// always @(posedge clk) begin
//     if (symbol_tick && !rst) begin
//         data_out <= {OUT_WIDTH{1'b0}};
//         nib_cnt  <= {NIB_COUNT_W{1'b0}};
//     end
//     else if (symbol_tick && cyc == 4'd13)
//         nib_cnt  <= {NIB_COUNT_W{1'b0}};
//     else if (symbol_tick) begin
//        if (!fill_sel)   // buf_A is being filled, so drain buf_B
//            data_out <= buf_B[nib_cnt*OUT_WIDTH +: OUT_WIDTH];
//        else             // buf_B is being filled, so drain buf_A
//             data_out <= buf_A[nib_cnt*OUT_WIDTH +: OUT_WIDTH];
//         nib_cnt <= nib_cnt + 1'b1;   // wraps 31->0
//     end
// end

always @(posedge clk) begin
    if (!rst) begin
        data_out <= {OUT_WIDTH{1'b0}};
        nib_cnt  <= {NIB_COUNT_W{1'b0}};
    end
    else if (symbol_tick) begin
        data_out <= buf_A[nib_cnt*OUT_WIDTH +: OUT_WIDTH];   // always latch the CURRENT nibble
        if (cyc == 5'd14)
            nib_cnt <= {NIB_COUNT_W{1'b0}};                   // but then resync the counter
        else
            nib_cnt <= nib_cnt + 1'b1;
    end
end
endmodule