module DVB_tx_top #(
    parameter BLOCK_LENGTH = 128,

    // Reed-Solomon parameters
    parameter RS_M = 8,
    parameter RS_K = 192,
    parameter RS_N = 208,
    parameter RS_T = 8,

    // Preamble / Control
    parameter PREAMBLE_WIDTH = 255,
    parameter CONTROL_WIDTH  = 256,

    parameter PREAMBLE_COUNTER_WIDTH   = 8,
    parameter CONTROL_COUNTER_WIDTH    = 8,
    parameter aes_word_counter_width   = 9,
    parameter crc_counter_width        = 5,

    // Data / Crc phase lengths (in symbol_ticks worth of "aes words" /
    // crc steps) - exposed here so testbenches can scale these down for
    // fast simulation instead of always paying the full 350/32 length.
    parameter aes_word_count           = 350,
    parameter crc_width                = 32,

    // Dummy phase (BPSK filter priming/flush) length, in symbol_ticks
    parameter dummy_width              = 40,
    parameter dummy_counter_width      = 6     // must hold up to dummy_width (40 -> 6 bits)
)
(
    input  wire clk_sample,
    input  wire rst,

    // Frame control
    input  wire sof,  

    // AES interface
    input  wire [BLOCK_LENGTH-1:0] plaintext_in,
    input  wire [BLOCK_LENGTH-1:0] aes_key,

    // Outputs
    output wire signed [15:0] preamble_bb,   // bpsk output
    output wire signed [15:0] I_out,         // 16 psk output
    output wire signed [15:0] Q_out,         // 16 psk output

    // Debug
    output wire [3:0] period_count_o,
    output wire [2:0] rs_current_state_o
);

    //----------------------------------------------------------------------
    // FSM outputs
    //----------------------------------------------------------------------
    wire dummy_en;
    wire preamble_en;
    wire control_en;
    wire data_en;
    wire crc_en;
    wire aes_fsm_en;
    wire [dummy_counter_width-1:0]    dummy_counter;
    wire [PREAMBLE_COUNTER_WIDTH-1:0] preamble_counter;
    wire [CONTROL_COUNTER_WIDTH-1:0]  control_counter;

    wire [aes_word_counter_width-1:0] aes_word_counter;
    wire [crc_counter_width-1:0]      crc_counter;

    // period_count_o is produced deep inside u_data (by
    // dvb_data_master_fsm's `period` counter) and is needed back inside
    // u_fsm to drive aes_word_counter's increment condition. It also
    // drives the top-level debug output port of the same name.
    wire [3:0] period_count_w;

    // cyc is produced by dvb_data_master_fsm (inside u_data) and is needed
    // inside u_fsm to detect the exact tick period 13 ends (cyc==31 &&
    // period==13), so aes_word_counter can be incremented precisely once
    // per codeword instead of for all 32 ticks period_count_o reads 13.
    wire [4:0] cyc_w;
    //----------------------------------------------------------------------
    // Bit from preamble/control register
    //----------------------------------------------------------------------
    wire bpsk_bit_pre_ctrl;

    //----------------------------------------------------------------------
    // BPSK baseband outputs
    //----------------------------------------------------------------------
    // wire   preamble_valid;


    reg [1:0] symbol_cnt;

    always @(posedge clk_sample) begin
        if (!rst)
            symbol_cnt <= 2'd0;
        else
            symbol_cnt <= symbol_cnt + 2'b1;
    end

    wire symbol_tick = (symbol_cnt == 2'd0);



    //----------------------------------------------------------------------
    // Transmission FSM
    //----------------------------------------------------------------------
    DVB_all_tx_fsm #(
        .preamble_width(PREAMBLE_WIDTH),
        .control_width(CONTROL_WIDTH),
        .BLOCK_LENGTH(BLOCK_LENGTH),
        .preamble_counter_width(PREAMBLE_COUNTER_WIDTH),
        .control_counter_width(CONTROL_COUNTER_WIDTH),
        .aes_word_count(aes_word_count),
        .crc_width(crc_width),
        .dummy_width(dummy_width),
        .dummy_counter_width(dummy_counter_width)
    ) u_fsm (
        .sof(sof),
        .clk_sample(clk_sample),
        .rst(rst),
        .period_count_o(period_count_w),
        .cyc(cyc_w),

        .dummy_en(dummy_en),
        .preamble_en(preamble_en),
        .control_en(control_en),
        .data_en(data_en),
        .crc_en(crc_en),              // Reserved for future use
        .aes_fsm_en(aes_fsm_en),
        .dummy_counter(dummy_counter),
        .preamble_counter(preamble_counter),
        .control_counter(control_counter),
        .aes_word_counter(aes_word_counter),
        .crc_counter(crc_counter)
    );

    //----------------------------------------------------------------------
    // Preamble / Control Pattern Generator
    //----------------------------------------------------------------------
    preamb_cont_reg #(
        .preamble_width(PREAMBLE_WIDTH),
        .control_width(CONTROL_WIDTH),
        .preamble_counter_width(PREAMBLE_COUNTER_WIDTH),
        .control_counter_width(CONTROL_COUNTER_WIDTH)
    ) u_pre_ctrl (

        .clk_sample(clk_sample),
        .rst(rst),
        .symbol_tick(symbol_tick),
        .aes_key(aes_key),

        .preamble_en(preamble_en),
        .control_en(control_en),

        .preamble_counter(preamble_counter),
        .control_counter(control_counter),

        .bpsk_bit_pre_ctrl(bpsk_bit_pre_ctrl)
    );

    //----------------------------------------------------------------------
    // Dummy phase bit pattern (BPSK filter priming/flush)
    //----------------------------------------------------------------------
    // Alternating 0/1 pattern: dummy_counter increments once per
    // symbol_tick while in the Dummy state, so its LSB toggles every
    // symbol_tick -> 0,1,0,1,... for the full dummy_width-bit run.
    wire dummy_bit = dummy_counter[0];

    // Feed the dummy pattern into the BPSK modulator input during the
    // Dummy phase, otherwise pass through the normal preamble/control bit.
    wire bpsk_bit_in = dummy_en ? dummy_bit : bpsk_bit_pre_ctrl;


    assign bpsk_en = preamble_en || dummy_en;
    //----------------------------------------------------------------------
    // BPSK Transmitter for preamble/control
    //----------------------------------------------------------------------
    bpsk_tx_bb_top u_bpsk (

        .rst(rst),
        .clk_sample(clk_sample),

        .bit_valid(symbol_tick),
        .bit_in(bpsk_bit_in),

        .tx_out(preamble_bb),
        .tx_valid(bpsk_en)
    );

    //----------------------------------------------------------------------
    // Data Path
    //----------------------------------------------------------------------
    dvb_data_top #(
        .BLOCK_LENGTH(BLOCK_LENGTH),
        .RS_M(RS_M),
        .RS_K(RS_K),
        .RS_N(RS_N),
        .RS_T(RS_T)
    ) u_data (

        .clk_sample(clk_sample),
        .rst(rst),

        .plaintext_in(plaintext_in),
        .aes_key(aes_key),

        .aes_fsm_en(aes_fsm_en),
        .data_en(data_en),

        .I_out(I_out),
        .Q_out(Q_out),

        .period_count_o(period_count_w),
        .rs_current_state_o(rs_current_state_o),
        .cyc_o(cyc_w)
    );

    assign period_count_o = period_count_w;

    // crc_en intentionally left unused for now.

endmodule