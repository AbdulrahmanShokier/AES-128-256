module encoder_core
#(
    parameter m = 8,
    parameter k = 223,
    parameter t = 16
)
(
    input              clk,
    input              rst,
    input      [m-1:0] data_in,
    
    // Control signals from FSM
    input              lfsr_clear,
    input              lfsr_enable,
    input              buffer_write_enable,
    input              output_data_select,
    input              input_counter_clear,
    input              input_counter_enable,
    input              output_counter_clear,
    input              output_counter_enable,
    
    // Outputs to FSM
    output reg [7:0]   input_counter,
    output reg [7:0]   output_counter,
    
    // Data output
    output reg [m-1:0] data_out
);

//========================= Internal Signals =====================================
reg [m-1:0] data_buffer [0:k-1];
reg [m-1:0] lfsr_regs [0:2*t-1];
wire [m-1:0] feedback;
wire [m-1:0] gf_mult_result [0:2*t-1];

integer i;

//========================= Feedback Calculation =================================
assign feedback = data_in ^ lfsr_regs[2*t-1];

//========================= GF Multipliers (Combinational) =======================
genvar g_idx;
generate
    for (g_idx = 0; g_idx < 2*t; g_idx = g_idx + 1) begin : gf_mult_gen
        gf_multiplier_comb #(
            .m(m)
        ) mult_inst (
            .op_a(feedback),
            .op_b(g(g_idx)),
            .result(gf_mult_result[g_idx])
        );
    end
endgenerate

//========================= Input Counter ========================================
always @(posedge clk)
begin
    if (!rst || input_counter_clear)
        input_counter <= 8'd0;
    else if (input_counter_enable)
        input_counter <= input_counter + 8'd1;
end


//========================= Data Buffer ==========================================
always @(posedge clk)
begin
    if (!rst)
    begin
        for (i = 0; i < k; i = i + 1)
            data_buffer[i] <= {m{1'b0}};
    end
    else if (buffer_write_enable)
    begin
        data_buffer[input_counter] <= data_in;
    end
end

//========================= LFSR Registers =======================================
always @(posedge clk)
begin
    if (!rst || lfsr_clear)
    begin
        for (i = 0; i < 2*t; i = i + 1)
            lfsr_regs[i] <= {m{1'b0}};
    end
    else if (lfsr_enable)
    begin
        // First register: just the multiplier output
        lfsr_regs[0] <= gf_mult_result[0];
        
        // Remaining registers: shift + XOR
        for (i = 1; i < 2*t; i = i + 1)
        begin
            lfsr_regs[i] <= lfsr_regs[i-1] ^ gf_mult_result[i];
        end
    end
end


//========================= Output Counter =======================================
always @(posedge clk)
begin
    if (!rst || output_counter_clear)
        output_counter <= 8'd0;
    else if (output_counter_enable)
        output_counter <= output_counter + 8'd1;
end



//========================= Output Multiplexer ===================================
always @(posedge clk)
begin
    if (!rst)
        data_out <= {m{1'b0}};
    else
    begin
        if (output_data_select == 1'b0)
            // Output data from buffer
            data_out <= data_buffer[output_counter];
        else
            // Output parity from LFSR (reverse order)
            data_out <= lfsr_regs[2*t-1 - output_counter];
    end
end

//========================= Generator Polynomial Function ========================
function [m-1:0] g;
    input [5:0] addr;
    begin
        case(addr)
            6'd0:  g = 8'h01;
            6'd1:  g = 8'h5F;
            6'd2:  g = 8'h8E;
            6'd3:  g = 8'h6B;
            6'd4:  g = 8'hF5;
            6'd5:  g = 8'h3A;
            6'd6:  g = 8'h8C;
            6'd7:  g = 8'hD9;
            6'd8:  g = 8'hE4;
            6'd9:  g = 8'h7B;
            6'd10: g = 8'h2F;
            6'd11: g = 8'hA8;
            6'd12: g = 8'h43;
            6'd13: g = 8'h9D;
            6'd14: g = 8'hC6;
            6'd15: g = 8'h52;
            6'd16: g = 8'hB7;
            6'd17: g = 8'h1E;
            6'd18: g = 8'h08;
            6'd19: g = 8'hF2;
            6'd20: g = 8'h3D;
            6'd21: g = 8'h91;
            6'd22: g = 8'h25;
            6'd23: g = 8'h7A;
            6'd24: g = 8'hDE;
            6'd25: g = 8'h6C;
            6'd26: g = 8'hFA;
            6'd27: g = 8'h59;
            6'd28: g = 8'hB1;
            6'd29: g = 8'h0D;
            6'd30: g = 8'h81;
            6'd31: g = 8'h4E;
            6'd32: g = 8'h01;
            default: g = 8'h00;
        endcase
    end
endfunction

endmodule