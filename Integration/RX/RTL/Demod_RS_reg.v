module demod_rs_reg #(
    parameter REG_WIDTH   = 8,
    parameter IN_WIDTH    = 4,
    parameter OUT_WIDTH   = 8,
    parameter BATCH_BYTES = 208   // bytes per decode batch (RS(208,192) codeword)
)
(
    input                           clk_sample,
    input                           rst,
    input [IN_WIDTH - 1 : 0]        data_in,
    input                           symbol_tick,

    output                          byte_tick,
    output reg [OUT_WIDTH - 1 : 0]  data_out,

    output                          sel,           // 0 = decoderA, 1 = decoderB
    output                          decoderA_en,   // pulses with byte_tick when sel==0
    output                          decoderB_en,   // pulses with byte_tick when sel==1
    output                          batch_done     // pulses on last byte of a batch
);

reg [REG_WIDTH / 2 - 1 : 0] data_reg;
reg                         byte_cnt;

always @(posedge clk_sample)
begin
    if (!rst)
        byte_cnt <= 1'd0;
    else if (symbol_tick)
        byte_cnt <= byte_cnt + 1'b1;
end

assign byte_tick = (byte_cnt == 1'd1);

always @(posedge clk_sample)
begin
    if (!rst)
        data_reg <= {REG_WIDTH{1'b0}};
    else if (symbol_tick && !byte_tick)
        data_reg[3:0] <= data_in;
end

always @(posedge clk_sample)
begin
    if (!rst)
        data_out <= {OUT_WIDTH{1'b0}};
    else if (symbol_tick && byte_tick)
        data_out <= {data_in, data_reg[3:0]};   // high nibble (just arrived) + stored low nibble
end

// ---------------- decoder selection (ping-pong) ----------------
reg [7:0] byte_cnt2;   // counts 0 .. BATCH_BYTES-1 within the current batch
reg       sel_r;

always @(posedge clk_sample)
begin
    if (!rst) begin
        byte_cnt2 <= 8'd0;
        sel_r     <= 1'b0;
    end
    else if (byte_tick) begin
        if (byte_cnt2 == BATCH_BYTES - 1) begin
            byte_cnt2 <= 8'd0;
            sel_r     <= ~sel_r;      // flip decoder for the next batch
        end
        else begin
            byte_cnt2 <= byte_cnt2 + 1'b1;
        end
    end
end

assign sel         = sel_r;
assign decoderA_en = byte_tick && (sel_r == 1'b0);
assign decoderB_en = byte_tick && (sel_r == 1'b1);
assign batch_done  = byte_tick && (byte_cnt2 == BATCH_BYTES - 1);

endmodule