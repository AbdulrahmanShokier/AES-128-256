module encoder_fsm
#(
    parameter k = 192,
    parameter n = 208,
    parameter t = 8
)
(
    input              clk,
    input              rst,
    input              symbol_tick,
    input              start_encode,
    input              data_valid,
    input      [7:0]   counter,
    input              start_parity,
    
    output reg [2:0]   current_state,
    output reg         lfsr_clear,
    output reg         lfsr_enable,
    output reg         output_data_select,    // 0: data , 1: parity
    output reg         data_out_valid,
    output reg         encoding_done,
    output reg         ready_for_data,
    output reg         counter_clear,
    output reg         counter_enable
);

//========================= State Definitions ====================================
localparam [2:0] IDLE          = 3'b000;
localparam [2:0] INIT          = 3'b011;
localparam [2:0] OUTPUT_DATA   = 3'b001;
localparam [2:0] WAIT_PARITY   = 3'b100;
localparam [2:0] OUTPUT_PARITY = 3'b010;

reg [2:0] next_state;

always @(posedge clk) begin
    if (symbol_tick && !rst)
        current_state <= IDLE;
    else if (symbol_tick)
        current_state <= next_state;
end

always @(*) begin
    next_state = current_state;

    case (current_state)
        IDLE: begin
            if (start_encode)
                next_state = INIT;
        end

        INIT: begin
            next_state = OUTPUT_DATA;
        end

        OUTPUT_DATA: begin
            if (counter == k-1 && data_valid) begin
                next_state = WAIT_PARITY;
            end        
        end

        WAIT_PARITY: begin
            if (start_parity)
                next_state = OUTPUT_PARITY;
            // else: hold here indefinitely
        end

        OUTPUT_PARITY: begin
            if (counter == k + 2*t - 1)
                next_state = IDLE;
        end

        default: next_state = IDLE;
    endcase
end

//========================= Output Logic =========================================
always @(*) begin
    // Default values
    lfsr_clear         = 1'b0;
    lfsr_enable        = 1'b0;
    output_data_select = 1'b0;
    data_out_valid     = 1'b0;
    encoding_done      = 1'b0;
    ready_for_data     = 1'b0;
    counter_clear      = 1'b0;
    counter_enable     = 1'b0;
    
    case (current_state)
        IDLE: begin
            ready_for_data = 1'b1;
        end
        
        INIT: begin
            lfsr_clear    = 1'b1;    // Clear LFSR for one full cycle
            counter_clear = 1'b1;    // Clear counter for one full cycle
        end
        
        OUTPUT_DATA: 
        begin
            ready_for_data = 1'b0;
            
            if (data_valid) begin
                lfsr_enable        = 1'b1;
                data_out_valid     = 1'b1;
                counter_enable     = 1'b1;
                output_data_select = 1'b0;
            end
        end

        WAIT_PARITY: begin
            // nothing needs to be asserted here - just sit and wait for the signal to start feeding out th parity bits
            // (all outputs already default to 0 from the top of the block)
        end
        
        OUTPUT_PARITY: 
        begin
            ready_for_data = 1'b0;
            output_data_select = 1'b1;
            data_out_valid     = 1'b1;
            counter_enable     = 1'b1;
            
            if (counter == k + 2*t - 1)
                encoding_done = 1'b1;
        end
        
        default: begin end
    endcase
end

endmodule