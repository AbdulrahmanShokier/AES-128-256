module DVB_end_to_end_top #(
    parameter BLOCK_LENGTH = 128,

    // Reed-Solomon parameters
    parameter RS_M = 8,
    parameter RS_K = 192,
    parameter RS_N = 208,
    parameter RS_T = 8,

    // Frame parameters
    parameter PREAMBLE_WIDTH = 255,
    parameter CONTROL_WIDTH  = 256,

    parameter PREAMBLE_COUNTER_WIDTH = 8,
    parameter CONTROL_COUNTER_WIDTH  = 8,
    parameter aes_word_counter_width = 9,
    parameter crc_counter_width      = 5,

    parameter aes_word_count         = 1,
    parameter crc_width              = 32,

    parameter dummy_width            = 40,
    parameter dummy_counter_width    = 6,

    // Receiver
    parameter DATA_WIDTH             = 16
)
(
    input  wire clk,
    input  wire rst,

    // TX inputs
    input  wire sof,
    input  wire [BLOCK_LENGTH-1:0] plaintext_in,
    input  wire [BLOCK_LENGTH-1:0] aes_key,

    // RX outputs
    output wire [CONTROL_WIDTH-1:0] Control_register,
    output wire                     Control_complete,

    output wire [127:0] aes_dec_out,
    output wire         aes_dec_valid,

    // Debug outputs
    output wire [3:0] period_count_o,
    output wire [2:0] rs_current_state_o
);

    //----------------------------------------------------------------------
    // Internal channel signals
    //----------------------------------------------------------------------
    wire signed [15:0] preamble_bb;
    wire signed [15:0] tx_I;
    wire signed [15:0] tx_Q;

    //----------------------------------------------------------------------
    // DVB Transmitter
    //----------------------------------------------------------------------
    DVB_tx_top #(
        .BLOCK_LENGTH(BLOCK_LENGTH),

        .RS_M(RS_M),
        .RS_K(RS_K),
        .RS_N(RS_N),
        .RS_T(RS_T),

        .PREAMBLE_WIDTH(PREAMBLE_WIDTH),
        .CONTROL_WIDTH(CONTROL_WIDTH),

        .PREAMBLE_COUNTER_WIDTH(PREAMBLE_COUNTER_WIDTH),
        .CONTROL_COUNTER_WIDTH(CONTROL_COUNTER_WIDTH),
        .aes_word_counter_width(aes_word_counter_width),
        .crc_counter_width(crc_counter_width),

        .aes_word_count(aes_word_count),
        .crc_width(crc_width),

        .dummy_width(dummy_width),
        .dummy_counter_width(dummy_counter_width)
    ) tx_inst (
        .clk_sample(clk),
        .rst(rst),

        .sof(sof),

        .plaintext_in(plaintext_in),
        .aes_key(aes_key),

        .preamble_bb(preamble_bb),
        .I_out(tx_I),
        .Q_out(tx_Q),

        .period_count_o(period_count_o),
        .rs_current_state_o(rs_current_state_o)
    );

    //----------------------------------------------------------------------
    // DVB Receiver
    //----------------------------------------------------------------------
    Rx_full_chain_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .Control_Length(CONTROL_WIDTH)
    ) rx_inst (
        .clk(clk),
        .rst(rst),

        .RxInBpsk(preamble_bb),
        .RxIn16pskI(tx_I),
        .RxIn16pskQ(tx_Q),

        .Control_register(Control_register),
        .Control_complete(Control_complete),

        .aes_dec_out(aes_dec_out),
        .aes_dec_valid(aes_dec_valid)
    );

endmodule