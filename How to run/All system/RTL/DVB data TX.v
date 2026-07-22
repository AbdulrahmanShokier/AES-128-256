module dvb_data_top #(
    parameter BLOCK_LENGTH = 128,
    parameter RS_M         = 8,
    parameter RS_K         = 192,
    parameter RS_N         = 208,
    parameter RS_T         = 8
)
(
    input  wire                       clk_sample,
    input  wire                       rst,

    input  wire [BLOCK_LENGTH-1:0]    plaintext_in,
    input  wire [BLOCK_LENGTH-1:0]    aes_key,
    input  wire                       aes_fsm_en,

    input  wire                       data_en,

    output wire signed [15:0]         I_out,
    output wire signed [15:0]         Q_out,

    output wire [3:0]                 period_count_o,
    output wire [2:0]                 rs_current_state_o,
    output wire [4:0]                 cyc_o
);

    reg [1:0] symbol_cnt;

    always @(posedge clk_sample) begin
        if (!rst)
            symbol_cnt <= 2'd0;
        else
            symbol_cnt <= symbol_cnt + 2'b1;
    end

    wire symbol_tick = (symbol_cnt == 2'd0);

    wire aes_valid_w;
    wire aes_rs_load_w;
    wire start_encode_w;
    wire rs_data_valid_w;
    wire start_parity_w;
    wire rs_mod_wr_en_w;
    wire ready_for_data_w;
    wire [4:0] cyc;
    assign cyc_o = cyc;

    dvb_data_master_fsm fsm_inst (
        .clk_sample      (clk_sample),
        .rst             (rst),
        .data_en         (data_en),
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

    wire [BLOCK_LENGTH-1:0] aes_out_w;
    wire                    aes_valid_out_w;

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

    wire [7:0] rs_data_out_w;
    wire       rs_data_out_valid_w;
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

    wire [3:0] rs_mod_nibble_w;
    wire       rs_mod_swap_w;

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
        .data_en     (data_en),
        .wr_en       (rs_mod_wr_en_w),
        .data_in     (rs_data_out_w),
        .data_out    (rs_mod_nibble_w),
        .cyc         (cyc)
    );

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
        .valid_in   (data_en),
        .data_in    (rs_mod_nibble_w),
        .I_out      (I_out),
        .Q_out      (Q_out)
    );

endmodule
