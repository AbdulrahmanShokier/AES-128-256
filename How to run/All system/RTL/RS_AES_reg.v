module rs_aes_reg #(
    parameter REG_WIDTH       = 128,
    parameter IN_WIDTH        = 8,
    parameter OUT_WIDTH       = 128,
    parameter COUNTER         = 208,   // kept for interface compatibility (unused here)
    parameter COUNTER_WIDTH   = 8
)
(
    input                           clk_sample,
    input                           rst,
    input [IN_WIDTH - 1 : 0]        data_in_decoderA,
    input [IN_WIDTH - 1 : 0]        data_in_decoderB,
    input                           sel,            // 0 = decoderA valid, 1 = decoderB valid
    input                           symbol_tick,
    input                           load,

    output                          word_tick,      // single-cycle pulse when a 128-bit word completes
    output reg [OUT_WIDTH - 1 : 0]  data_out
);

localparam NUM_BYTES = REG_WIDTH / IN_WIDTH;   // 128/8 = 16
localparam CNT_W     = $clog2(NUM_BYTES);      // 4

reg [REG_WIDTH - 1 : 0] data_reg;
reg [CNT_W - 1 : 0]     byte_cnt;

wire [IN_WIDTH - 1 : 0] data_in = sel ? data_in_decoderB : data_in_decoderA;

// pulses exactly one clk_sample cycle, only on the tick that actually completes a word
assign word_tick = load && (byte_cnt == NUM_BYTES - 1);

// byte counter - only advances while load is high
always @(posedge clk_sample)
begin
    if (!rst)
        byte_cnt <= {CNT_W{1'b0}};
    else if (load) begin
        if (byte_cnt == NUM_BYTES - 1)
            byte_cnt <= {CNT_W{1'b0}};
        else
            byte_cnt <= byte_cnt + 1'b1;
    end
end

// shift-in the incoming byte while load is high (byte order reversed)
always @(posedge clk_sample)
begin
    if (!rst)
        data_reg <= {REG_WIDTH{1'b0}};
    else if (load)
        data_reg <= {data_in, data_reg[REG_WIDTH - 1 : IN_WIDTH]};
end

// latch the completed 128-bit word on the 16th byte (must match the same shift convention)
always @(posedge clk_sample)
begin
    if (!rst)
        data_out <= {OUT_WIDTH{1'b0}};
    else if (word_tick)
        data_out <= {data_in, data_reg[REG_WIDTH - 1 : IN_WIDTH]};
end

endmodule