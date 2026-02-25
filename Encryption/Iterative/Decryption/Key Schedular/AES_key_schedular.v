module AES_key_schedular
(
    input wire clk,
    input wire [1:0] control_signal,
    input wire [127:0] load_key_in,
    input wire [3:0] round_number,
    output wire [127:0] round_key_out
);


    wire [127:0] out_KeyExp_forward;
    wire [127:0] out_KeyExp_reverse;
    reg [127:0] round_key_out_register;
    reg  [127:0] MUX_OUT;

    always @(*)begin
        case(control_signal)
            2'b00: MUX_OUT = round_key_out;
            2'b01: MUX_OUT = load_key_in;
            2'b10: MUX_OUT = out_KeyExp_forward;
            2'b11: MUX_OUT = out_KeyExp_reverse;
            default: MUX_OUT = round_key_out;
        endcase 
    end


    always @(posedge clk) begin
        round_key_out_register <= MUX_OUT;
    end
    assign round_key_out = round_key_out_register;


    AES_KeyExpansion_Forward_calc forward_calc_instance(
        .word_in_0(round_key_out[127:96]),
        .word_in_1(round_key_out[95:64]),
        .word_in_2(round_key_out[63:32]),
        .word_in_3(round_key_out[31:0]),
        .round_number(round_number),
        .next_round_word_0(out_KeyExp_forward[127:96]),
        .next_round_word_1(out_KeyExp_forward[95:64]),
        .next_round_word_2(out_KeyExp_forward[63:32]),
        .next_round_word_3(out_KeyExp_forward[31:0])
    );

    AES_KeyExpansion_Reverse_calc reverse_calc_instance(
        .word_in_0(round_key_out[127:96]),
        .word_in_1(round_key_out[95:64]),
        .word_in_2(round_key_out[63:32]),
        .word_in_3(round_key_out[31:0]),
        .round_number(round_number),
        .previous_round_word_0(out_KeyExp_reverse[127:96]),
        .previous_round_word_1(out_KeyExp_reverse[95:64]),
        .previous_round_word_2(out_KeyExp_reverse[63:32]),
        .previous_round_word_3(out_KeyExp_reverse[31:0])
    );


    

endmodule //AES_key_schedular