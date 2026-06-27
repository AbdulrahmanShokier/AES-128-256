module preamb_cont_reg #(
    parameter preamble_width         = 255,
    parameter control_width          = 256,
    parameter preamble_counter_width = 8,
    parameter control_counter_width  = 8
)
(
    input  wire                                   clk_sample,
    input  wire                                   rst,
    input  wire                                   symbol_tick,

    input  wire                                   preamble_en,
    input  wire                                   control_en,

    input  wire [preamble_counter_width-1:0]      preamble_counter,
    input  wire [control_counter_width-1:0]       control_counter,

    output wire                                   bpsk_bit_pre_ctrl
);

    // ------------------------------------------------------------------
    // Placeholder bit patterns. Swap these for the real preamble / control
    // content later - everything downstream just reads bits out of these
    // localparams MSB-first, so changing the value here is the only edit
    // needed. No register is needed to hold them since the pattern itself
    // never changes at runtime - only the read position (the counter) does.
    // ------------------------------------------------------------------
    localparam [preamble_width-1:0] PREAMBLE_PATTERN = {(preamble_width+1)/2{2'b10}}; // placeholder: 1010...

    localparam [control_width-1:0] CONTROL_PATTERN   = {(control_width/8){8'hA5}};    // placeholder: 0xA5 repeating

    // ====================== Serial bit-out to BPSK modulator =================
    // MSB-first: on the Nth symbol_tick a state's enable is high (N = that
    // state's counter value), emit bit [width-1-N] of that pattern.
    // Registered output so the bit changes only on clk_sample.

    reg bpsk_bit_pre_ctrl_reg;

    always @(posedge clk_sample) begin
        if (!rst) begin
            bpsk_bit_pre_ctrl_reg <= 1'b0;
        end
        else if(symbol_tick) begin
            if (preamble_en)
                bpsk_bit_pre_ctrl_reg <= PREAMBLE_PATTERN[preamble_width-1-preamble_counter];
            else if (control_en)
                bpsk_bit_pre_ctrl_reg <= CONTROL_PATTERN[control_width-1-control_counter];
            else
                bpsk_bit_pre_ctrl_reg <= 1'b0;
        end
    end

    assign bpsk_bit_pre_ctrl = bpsk_bit_pre_ctrl_reg;

endmodule