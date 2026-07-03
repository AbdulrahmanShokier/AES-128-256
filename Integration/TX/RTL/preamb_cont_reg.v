module preamb_cont_reg #(
    parameter preamble_width         = 255,
    parameter control_width          = 256,
    parameter preamble_counter_width = 8,
    parameter AES_KEY_width          = 128,
    parameter control_counter_width  = 8
)
(
    input  wire                                   clk_sample,
    input  wire                                   rst,
    input  wire                                   symbol_tick,

    input  wire                                   preamble_en,
    input  wire                                   control_en,
    input  wire [AES_KEY_width-1:0]               aes_key,

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
    localparam [preamble_width-1:0] PREAMBLE_PATTERN = 255'b100001000101110101111011011111000011010011010110110101000001001110110010010011000000111010010001110001000000010110001111010000111111110010000101001111101010111000001100010101100110010111111011110011011101110010101001010001001011010001100111001101; 

    localparam [control_width-1:0] CONTROL_PATTERN   = {aes_key,aes_key};    // placeholder: 0xA5 repeating

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