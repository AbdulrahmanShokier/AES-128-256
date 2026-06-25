module dvb_top #(
    parameter BLOCK_LENGTH = 128,   // AES block size
    parameter RS_M         = 8,     // RS symbol width (bits)
    parameter RS_K         = 192,   // RS data symbols
    parameter RS_N         = 208,   // RS codeword symbols
    parameter RS_T         = 8      // RS error-correcting capability
)
(
    input  wire                       clk_sample,   // fast clock; modulator's native rate (4x symbol rate)
    input  wire                       rst,

    // AES inputs - plaintext and key are expected to be held stable by
    // whatever feeds this design (e.g. testbench / upstream source FIFO)
    input  wire [BLOCK_LENGTH-1:0]    plaintext_in,
    input  wire [BLOCK_LENGTH-1:0]    aes_key,
    input  wire                       aes_fsm_en,   // one-time key-schedule trigger (testbench-driven per your plan)

    // Modulator output
    output wire signed [15:0]         I_out,
    output wire signed [15:0]         Q_out,

    // Debug/monitoring
    output wire [3:0]                 period_count_o,
    output wire [2:0]                 rs_current_state_o
);

    // ===================== Symbol-rate tick generator =====================
    // clk_sample runs 4x faster than the "real" symbol cadence everything
    // else (FSM, AES, RS, buffers) was designed around. symbol_tick pulses
    // once every 4 clk_sample cycles and gates every other module's clocked
    // logic so they effectively advance once per "real" cycle.
    reg [1:0] symbol_cnt;

    always @(posedge clk_sample) begin
        if (!rst)
            symbol_cnt <= 2'd0;
        else
            symbol_cnt <= symbol_cnt + 2'b1;
    end

    wire symbol_tick = (symbol_cnt == 2'd0);

    // ===================== Master FSM =====================
    wire aes_valid_w;
    wire aes_rs_load_w;
    wire start_encode_w;
    wire rs_data_valid_w;
    wire start_parity_w;
    wire rs_mod_wr_en_w;
    wire ready_for_data_w;
    wire [4:0] cyc;

    dvb_master_fsm fsm_inst (
        .clk_sample      (clk_sample),
        .rst             (rst),
        .symbol_tick     (symbol_tick),
        .ready_for_data  (ready_for_data_w),
        .aes_valid       (aes_valid_w),
        .aes_rs_load     (aes_rs_load_w),
        .start_encode    (start_encode_w),
        .rs_data_valid   (rs_data_valid_w),
        .start_parity    (start_parity_w),
        .rs_mod_wr_en    (rs_mod_wr_en_w),
        .cyc             (cyc),
        .period_count_o  (period_count_o)
    );

    // ===================== AES =====================
    wire [BLOCK_LENGTH-1:0] aes_out_w;
    wire                    aes_valid_out_w;   // AES's own pipeline-valid (en_pipe[10]), NOT used for timing here -
                                                 // dvb_master_fsm's open-loop cyc==11 already assumes this lines up.

    AES_enc #(.BLOCK_LENGTH(BLOCK_LENGTH)) aes_inst (
        .clk         (clk_sample),
        .rst         (rst),
        .symbol_tick (symbol_tick),
        .IN          (plaintext_in),
        .KEY         (aes_key),
        .valid       (aes_valid_w),
        .fsm_en      (aes_fsm_en),
        .OUT         (aes_out_w),
        .valid_out   (aes_valid_out_w)
    );

    // ===================== AES -> RS byte serializer =====================
    wire [7:0] aes_rs_byte_w;

    aes_rs_reg #(
        .IN_WIDTH    (128),
        .REG_WIDTH   (128),
        .OUT_WIDTH   (8),
        .COUNT_WIDTH (4)
    ) aes_rs_reg_inst (
        .clk         (clk_sample),
        .rst         (rst),
        .symbol_tick (symbol_tick),
        .load        (aes_rs_load_w),
        .data_in     (aes_out_w),
        .data_out    (aes_rs_byte_w)
    );

    // ===================== RS encoder =====================
    wire [7:0] rs_data_out_w;
    wire       rs_data_out_valid_w;   // exposed but not used for rs_mod_reg's wr_en per your decision
    wire       rs_encoding_done_w;

    encoder_top #(
        .m(RS_M), .k(RS_K), .n(RS_N), .t(RS_T)
    ) rs_inst (
        .clk             (clk_sample),
        .rst             (rst),
        .symbol_tick     (symbol_tick),
        .data_in         (aes_rs_byte_w),
        .data_valid      (rs_data_valid_w),
        .start_encode    (start_encode_w),
        .start_parity    (start_parity_w),
        .data_out        (rs_data_out_w),
        .data_out_valid  (rs_data_out_valid_w),
        .encoding_done   (rs_encoding_done_w),
        .ready_for_data  (ready_for_data_w),
        .current_state   (rs_current_state_o)
    );

    // ===================== RS -> modulator double buffer =====================
    wire [3:0] rs_mod_nibble_w;
    wire       rs_mod_swap_w;   // exposed, currently unused by the master FSM per your decision

    rs_mod_reg #(
        .IN_WIDTH     (8),
        .REG_WIDTH    (128),
        .OUT_WIDTH    (4),
        .BYTE_COUNT_W (4),
        .NIB_COUNT_W  (5)
    ) rs_mod_reg_inst (
        .clk         (clk_sample),
        .rst         (rst),
        .symbol_tick (symbol_tick),
        .wr_en       (rs_mod_wr_en_w),
        .data_in     (rs_data_out_w),
        .data_out    (rs_mod_nibble_w),
        .cyc         (cyc)
//        .swap        (rs_mod_swap_w)
    );

    // ===================== Modulator =====================
    // Runs on clk_sample directly (its native rate, NOT gated by symbol_tick -
    // the modulator handles its own internal 4x upsampling on its own).
    top_16psk_baseband #(
        .DATA_WIDTH    (16),
        .FRAC_WIDTH    (14),
        .NO_BITS       (4),
        .UPS_FACTOR    (4),
        .COUNTER_WIDTH (2),
        .NUM_TAPS      (65),
        .COEFF_WIDTH   (16)
    ) modulator_inst (
        .clk_sample (clk_sample),
        .rst        (rst),
        .valid_in   (1'b1),
        .data_in    (rs_mod_nibble_w),
        .I_out      (I_out),
        .Q_out      (Q_out)
    );

endmodule