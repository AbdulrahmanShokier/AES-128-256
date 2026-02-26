module encoder_fsm
#(
    parameter k = 223,
    parameter t = 16
)
(
    input              clk,
    input              rst,
    input              start_encode,
    input              data_valid,
    input      [7:0]   input_counter,
    input      [7:0]   output_counter,
    
    output reg [2:0]   current_state,
    output reg         lfsr_clear,
    output reg         lfsr_enable,
    output reg         buffer_write_enable,
    output reg         output_data_select,    // 0: data buffer, 1: parity
    output reg         data_out_valid,
    output reg         encoding_done,
    output reg         ready_for_data,
    output reg         buffer_is_full,
    output reg         input_counter_clear,
    output reg         input_counter_enable,
    output reg         output_counter_clear,
    output reg         output_counter_enable
);

//========================= State Definitions ====================================
localparam [2:0] IDLE          = 3'b000;
localparam [2:0] LOAD_DATA     = 3'b001;
localparam [2:0] OUTPUT_DATA   = 3'b010;
localparam [2:0] OUTPUT_PARITY = 3'b011;

reg [2:0] next_state;

//========================= State Register =======================================
always @(posedge clk)
begin
    if (!rst)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

//========================= Next State Logic =====================================
always @(*)
begin
    next_state = current_state;
    
    case (current_state)
        IDLE: begin
            if (start_encode)
                next_state = LOAD_DATA;
        end
        
        LOAD_DATA: begin
            if (input_counter == k-1 && data_valid)
                next_state = OUTPUT_DATA;
        end
        
        OUTPUT_DATA: begin
            if (output_counter == k-1)
                next_state = OUTPUT_PARITY;
        end
        
        OUTPUT_PARITY: begin
            if (output_counter == 2*t-1)
                next_state = IDLE;
        end
        
        default: next_state = IDLE;
    endcase
end

//========================= Output Logic =========================================
always @(*)
begin
    // Default values
    lfsr_clear            = 1'b0;
    lfsr_enable           = 1'b0;
    buffer_write_enable   = 1'b0;
    output_data_select    = 1'b0;
    data_out_valid        = 1'b0;
    encoding_done         = 1'b0;
    ready_for_data        = 1'b0;
    buffer_is_full        = 1'b0;
    input_counter_clear   = 1'b0;
    input_counter_enable  = 1'b0;
    output_counter_clear  = 1'b0;
    output_counter_enable = 1'b0;
    
    case (current_state)
        IDLE: begin
            lfsr_clear           = 1'b1;
            input_counter_clear  = 1'b1;
            output_counter_clear = 1'b1;
            ready_for_data       = 1'b1;
        end
        
        LOAD_DATA: begin
            ready_for_data       = 1'b1;
            output_counter_clear = 1'b1;
            
            if (data_valid) begin
                buffer_write_enable  = 1'b1;
                lfsr_enable          = 1'b1;
                input_counter_enable = 1'b1;
                
                if (input_counter == k-1)
                    buffer_is_full = 1'b1;
            end
        end
        
        OUTPUT_DATA: begin
            output_data_select    = 1'b0;  // Select data buffer
            data_out_valid        = 1'b1;
            output_counter_enable = 1'b1;
        end
        
        OUTPUT_PARITY: begin
            output_data_select    = 1'b1;  // Select parity (LFSR)
            data_out_valid        = 1'b1;
            output_counter_enable = 1'b1;
            
            if (output_counter == 2*t-1)
                encoding_done = 1'b1;
        end
        
        default: begin
            // Keep defaults
        end
    endcase
end

endmodule