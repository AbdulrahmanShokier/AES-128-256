module DVB_all_tx_fsm #(
    parameter peramble_width           = 255,
    parameter control_width            = 256,
    parameter aes_word_count           = 350,
    parameter crc_width                = 32,
    parameter BLOCK_LENGTH             = 128,  // AES block size
    parameter peramble_counter_width   = 8,
    parameter control_counter_width    = 8,
    parameter aes_word_counter_width   = 9,
    parameter crc_counter_width        = 5
)
(
    input  wire                                  sof,          // start of frame
    input  wire                                  clk_sample,   // fast clock; modulator's native rate (4x symbol rate)
    input  wire                                  rst,
    input  wire [3 : 0]                          period_count_o,
    input  wire [4 : 0]                          cyc,

    output reg                                   preamble_en,
    output reg                                   control_en,
    output reg                                   data_en,
    output reg                                   crc_en,
    output reg                                   aes_fsm_en,
    output reg [peramble_counter_width - 1 : 0]  preamble_counter,
    output reg [control_counter_width - 1 : 0]   control_counter,
    output reg [aes_word_counter_width - 1 : 0]  aes_word_counter,
    output reg [crc_counter_width - 1 : 0]       crc_counter
);



    parameter [2:0]
        IDLE      = 3'b000,
        Preamble  = 3'b001,
        Control   = 3'b010,
        Data      = 3'b011,
        Crc       = 3'b100;

    reg [1:0] symbol_cnt;

    always @(posedge clk_sample) begin
        if (!rst)
            symbol_cnt <= 2'd0;
        else
            symbol_cnt <= symbol_cnt + 2'b1;
    end

    wire symbol_tick = (symbol_cnt == 2'd0);

    reg [2:0] current_state, next_state;

    always @(posedge clk_sample) begin
        if (!rst)
            current_state <= IDLE;
        else if (symbol_tick)
            current_state <= next_state;
    end

    always @(*) begin
        next_state = current_state;
        case (current_state)
            IDLE:
                next_state = sof ? Preamble : IDLE;

            Preamble:
                next_state = (preamble_counter == peramble_width - 1) ? Control : Preamble;

            Control:
                next_state = (control_counter == control_width - 1) ? Data : Control;

            Data:
                next_state = (aes_word_counter == aes_word_count - 1) ? Crc : Data;

            Crc:
                next_state = (crc_counter == crc_width - 1) ? IDLE : Crc;

            default:
                next_state = IDLE;
        endcase
    end

    always @(posedge clk_sample) begin
        if (!rst)
            preamble_counter <= 0;
        else if (symbol_tick) begin
            if (current_state == Preamble)
                preamble_counter <= preamble_counter + 1'b1;
            else
                preamble_counter <= 0;
        end
    end

    always @(posedge clk_sample) begin
        if (!rst)
            control_counter <= 0;
        else if (symbol_tick) begin
            if (current_state == Control)
                control_counter <= control_counter + 1'b1;
            else
                control_counter <= 0;
        end
    end

    // ====================== aes_word_counter increment timing ================
    // Goal: increment aes_word_counter exactly ONCE per codeword, 14
    // symbol_ticks after period 13 finishes (cyc wraps 31->0 while
    // period==13) - i.e. once the parity has had time to finish modulating
    // - rather than once per tick for all 32 ticks period stays at 13.
    //
    // period13_end_pulse fires for exactly one symbol_tick: the tick where
    // cyc==31 and period_count_o==13 together (the last tick of period 13,
    // right before period wraps back to 1 for the next codeword).
    wire period13_end_pulse = symbol_tick && (current_state == Data) &&
                               (cyc == 5'd31) && (period_count_o == 4'd13);

    // delay_cnt counts down from 14 to 0 once armed by period13_end_pulse.
    // It is re-armed fresh every codeword by period13_end_pulse, so it
    // cannot fire early/extra even if somehow re-triggered before finishing
    // (period13_end_pulse only occurs once every 13*32 = 416 ticks, far
    // longer than the 14-tick countdown, so this is a non-issue here, but
    // the explicit "armed" flag below keeps it correct regardless).
    reg [3:0] delay_cnt;
    reg       armed;
    wire      aes_word_inc_pulse = armed && (delay_cnt == 4'd0) && symbol_tick;

    always @(posedge clk_sample) begin
        if (!rst) begin
            delay_cnt <= 4'd0;
            armed     <= 1'b0;
        end
        else if (symbol_tick) begin
            if (period13_end_pulse) begin
                delay_cnt <= 4'd13;
                armed     <= 1'b1;
            end
            else if (armed) begin
                if (delay_cnt == 4'd0)
                    armed <= 1'b0;          // pulse just fired this tick - disarm
                else
                    delay_cnt <= delay_cnt - 1'b1;
            end
        end
    end

    always @(posedge clk_sample) begin
        if (!rst)
            aes_word_counter <= 0;
        else if (symbol_tick) begin
            if (current_state != Data)
                aes_word_counter <= 0;
            else if (aes_word_inc_pulse)
                aes_word_counter <= aes_word_counter + 1'b1;
        end
    end

    always @(posedge clk_sample) begin
        if (!rst)
            crc_counter <= 0;
        else if (symbol_tick) begin
            if (current_state == Crc)
                crc_counter <= crc_counter + 1'b1;
            else
                crc_counter <= 0;
        end
    end

    always @(posedge clk_sample) begin
        if (!rst) begin
            preamble_en <= 1'b0;
            control_en  <= 1'b0;
            data_en     <= 1'b0;
            crc_en      <= 1'b0;
            aes_fsm_en  <= 1'b0;
        end
        else if (symbol_tick) begin
            preamble_en <= (next_state == Preamble);
            control_en  <= (next_state == Control);
            data_en     <= (next_state == Data);
            crc_en      <= (next_state == Crc);
            aes_fsm_en  <= (current_state == Control) && (control_counter == 9'd254);
        end
    end

endmodule