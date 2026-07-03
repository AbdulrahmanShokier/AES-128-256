module Rx_full_chain_top #(
    parameter DATA_WIDTH     = 16,
    parameter Control_Length = 256
)
(
    input  wire clk,
    input  wire rst,

    input  wire signed [DATA_WIDTH-1:0] RxInBpsk,
    input  wire signed [DATA_WIDTH-1:0] RxIn16pskI,
    input  wire signed [DATA_WIDTH-1:0] RxIn16pskQ,

    output wire [Control_Length-1:0] Control_register,
    output wire                      Control_complete,

    output wire [127:0] aes_dec_out,
    output wire         aes_dec_valid
);

    // ---------------- Rx_bpsk_Top ----------------
    wire signed [DATA_WIDTH-1:0] I_buf, Q_buf;
    wire                         payload_valid;

    Rx_bpsk_Top #(.DATA_WIDTH(DATA_WIDTH), .Control_Length(Control_Length)) u_rx_bpsk (
        .clk                   (clk),
        .rst                   (rst),
        .RxInBpsk              (RxInBpsk),
        .RxIn16pskI            (RxIn16pskI),
        .RxIn16pskQ            (RxIn16pskQ),
        .Control_register      (Control_register),
        .Control_complete      (Control_complete),
        .sample16pskI_buffered (I_buf),
        .sample16pskQ_buffered (Q_buf),
        .payload_valid         (payload_valid)
    );

    // ---------------- psk16_demod_top ----------------
    wire [3:0]  symbol;
    wire [15:0] angle_wave;
    wire        demod_valid_out;

    psk16_demod_top u_demod16 (
        .clk        (clk),
        .rst        (rst),
        .valid_in   (payload_valid),
        .I          (I_buf),
        .Q          (Q_buf),
        .symbol     (symbol),
        .angle_wave (angle_wave),
        .valid_out  (demod_valid_out)
    );

    // ---------------- demod_rs_reg ----------------
    // NOTE: sel/decoderA_en/decoderB_en/batch_done left unconnected —
    // Rx_ctrl_fsm.enable_A/enable_B are the real enables now (see item 2).
    wire        byte_tick;
    wire [7:0]  demod_byte_out;

    demod_rs_reg #(.BATCH_BYTES(208)) u_demod_rs_reg (
        .clk_sample  (clk),
        .rst         (rst),
        .data_in     (symbol),
        .symbol_tick (demod_valid_out),   
        .byte_tick   (byte_tick),
        .data_out    (demod_byte_out),
        .sel         (),
        .decoderA_en (),
        .decoderB_en (),
        .batch_done  ()
    );

    // ---------------- Rx_ctrl_fsm ----------------
    wire enable_A, enable_B, load, aes_valid_pulse, nibble_batch_done;
    wire word_tick;
    wire decode_fail_A, decode_fail_B;
    wire fsm_en_to_aes; 

wire sel_from_fsm;

    Rx_ctrl_fsm #(.NUM_BATCHES(4) /* TODO: set real value */) u_rx_ctrl_fsm (
        .clk_sample           (clk),
        .rst                  (rst),
        .symbol_tick          (demod_valid_out),  
        .valid                (payload_valid),    
        .decode_fail_A        (decode_fail_A),
        .decode_fail_B        (decode_fail_B),
        .word_tick            (word_tick),
        .enable_A             (enable_A),
        .enable_B             (enable_B),
        .load                 (load),
        .aes_valid            (aes_valid_pulse),
        .nibble_batch_done_o  (nibble_batch_done),
        .sel                  (sel_from_fsm)
    );

    // ---------------- Top_decoder A / B ----------------
    wire outA_valid, outB_valid;
    wire [7:0] CxA, CxB;
    wire failA, readyA, doneA;
    wire failB, readyB, doneB;
    wire inA_tick, outA_tick, inB_tick, outB_tick;

    Top_decoder u_decoderA (
        .clock                  (clk),
        .reset                  (rst),
        .enable                 (enable_A),      // item 2: confirmed
        .received_symbol        (demod_byte_out),
        .input_symbol_tick      (inA_tick),
        .output_symbol_tick     (outA_tick),
        .out_valid              (outA_valid),
        .Cx                     (CxA),
        .decode_fail            (failA),          // item 4: decode_failed removed
        .decoder_ready          (readyA),
        .frame_done             (doneA)
    );

    Top_decoder u_decoderB (
        .clock                  (clk),
        .reset                  (rst),
        .enable                 (enable_B),
        .received_symbol        (demod_byte_out),
        .input_symbol_tick      (inB_tick),
        .output_symbol_tick     (outB_tick),
        .out_valid              (outB_valid),
        .Cx                     (CxB),
        .decode_fail            (failB),
        .decoder_ready          (readyB),
        .frame_done             (doneB)
    );

    assign decode_fail_A = failA;
    assign decode_fail_B = failB;

    // ---------------- rs_aes_reg ----------------
    wire [127:0] aes_word;

    rs_aes_reg u_rs_aes_reg (
        .clk_sample        (clk),
        .rst               (rst),
        .data_in_decoderA  (CxA),
        .data_in_decoderB  (CxB),
        .sel               (sel_from_fsm),                 // TODO #7
        .symbol_tick       (outA_tick | outB_tick),   
        .load              (load),
        .word_tick         (word_tick),
        .data_out          (aes_word)
    );

    // ---------------- AES_dec ----------------
    // TODO #8: key comes from Control_register — exact bit slice not yet confirmed
    wire [127:0] aes_key = Control_register[127:0]; // placeholder slice

    AES_dec #(.BLOCK_LENGTH(128)) u_aes_dec (
        .clk         (clk),
        .rst         (rst),
        .symbol_tick (outA_tick | outB_tick),      // NEW: must connect to whichever tick drives the round pipeline / key generator
        .IN          (aes_word),
        .KEY         (aes_key),         
        .enable      (aes_valid_pulse),
        .fsm_en      (payload_valid),    
        .OUT         (aes_dec_out),
        .valid_out   (aes_dec_valid)
    );

endmodule