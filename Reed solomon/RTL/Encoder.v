module encoder_top
#(
    parameter m = 8,
    parameter k = 223,
    parameter n = 255,
    parameter t = 16
)
(
    input              clk,
    input              rst,
    input      [m-1:0] data_in,
    input              data_valid,
    input              start_encode,
    
    output     [m-1:0] data_out,
    output             data_out_valid,
    output             encoding_done,
    output             ready_for_data,
    output             buffer_is_full,
    output     [2:0]   current_state
);

//========================= Internal Wires =======================================
// FSM to Datapath
wire        lfsr_clear;
wire        lfsr_enable;
wire        buffer_write_enable;
wire        output_data_select;
wire        input_counter_clear;
wire        input_counter_enable;
wire        output_counter_clear;
wire        output_counter_enable;

// Datapath to FSM
wire [7:0]  input_counter;
wire [7:0]  output_counter;

// Data buffer (optional exposure)
wire [m-1:0] data_buffer [0:k-1];

//========================= FSM Instantiation ====================================
encoder_fsm #(
    .k(k),
    .t(t)
) fsm_inst (
    .clk                    (clk),
    .rst                    (rst),
    .start_encode           (start_encode),
    .data_valid             (data_valid),
    .input_counter          (input_counter),
    .output_counter         (output_counter),
    
    .current_state          (current_state),
    .lfsr_clear             (lfsr_clear),
    .lfsr_enable            (lfsr_enable),
    .buffer_write_enable    (buffer_write_enable),
    .output_data_select     (output_data_select),
    .data_out_valid         (data_out_valid),
    .encoding_done          (encoding_done),
    .ready_for_data         (ready_for_data),
    .buffer_is_full         (buffer_is_full),
    .input_counter_clear    (input_counter_clear),
    .input_counter_enable   (input_counter_enable),
    .output_counter_clear   (output_counter_clear),
    .output_counter_enable  (output_counter_enable)
);

//========================= Datapath Instantiation ===============================
encoder_datapath #(
    .m(m),
    .k(k),
    .t(t)
) datapath_inst (
    .clk                    (clk),
    .rst                    (rst),
    .data_in                (data_in),
    
    .lfsr_clear             (lfsr_clear),
    .lfsr_enable            (lfsr_enable),
    .buffer_write_enable    (buffer_write_enable),
    .output_data_select     (output_data_select),
    .input_counter_clear    (input_counter_clear),
    .input_counter_enable   (input_counter_enable),
    .output_counter_clear   (output_counter_clear),
    .output_counter_enable  (output_counter_enable),
    
    .input_counter          (input_counter),
    .output_counter         (output_counter),
    .data_out               (data_out),
    .data_buffer            (data_buffer)
);

endmodule