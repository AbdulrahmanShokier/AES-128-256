module encoder_core
#(
    parameter m = 8, //GF(2^8)
    parameter k = 192, //n=208
    parameter t = 8
)
(
    input              clk,
    input              rst,
    input      [m-1:0] data_in,

    // Control signals from FSM
    input              lfsr_clear,
    input              lfsr_enable,
    input              output_data_select,
    input              counter_clear,
    input              counter_enable,
    
    // Outputs to FSM
    output reg [7:0]   counter,
    
    // Data output
    output reg [m-1:0] data_out

);

//========================= Internal Signals =====================================
reg  [m-1:0] lfsr_regs [0:2*t-1];
wire [m-1:0] feedback;
wire [m-1:0] gf_mult_result [0:2*t-1];

integer i;


//========================= GF Multipliers (Combinational) =======================
genvar g_idx;
generate
    for (g_idx = 0; g_idx < 2*t; g_idx = g_idx + 1) begin : gf_mult_gen
        gf_multiplier #(
            .m(m)
        ) mult_inst (
            .op_a(feedback), // Feedback value from LFSR
            .op_b(g(g_idx)), // Coefficients from generator polynomial g(X)
            .result(gf_mult_result[g_idx])
        );
    end
endgenerate


//========================= LFSR Registers =======================================
reg [m-1:0] lfsr_next [0:2*t-1];

always @(*) begin
    lfsr_next[0] = gf_mult_result[0];

    for(i=1;i<2*t;i=i+1)
        lfsr_next[i] = lfsr_regs[i-1] ^ gf_mult_result[i];
end

always @(posedge clk) 
begin
    if(!rst || lfsr_clear)
    begin
        for(i=0;i<2*t;i=i+1)
            lfsr_regs[i] <= 0;
    end

    else if(lfsr_enable)
    begin
        for(i=0;i<2*t;i=i+1)
            lfsr_regs[i] <= lfsr_next[i];
    end
end


//=========================  Counter =======================================
always @(posedge clk)
begin
    if (!rst || counter_clear)
        counter <= 8'd0;
    else if (counter_enable)
        counter <= counter + 8'd1;
end

//========================= Feedback Calculation =================================

assign feedback = (lfsr_enable) ? (data_in ^ lfsr_regs[2*t-1]) : {m{1'b0}};

//========================= Output Multiplexer ===================================
reg [7:0] parity_index_reg;

// Register parity_index one cycle ahead
always @(posedge clk) 
begin
    if (!rst || counter_clear)
        parity_index_reg <= 8'd0;

    else if (output_data_select && counter_enable)
        parity_index_reg <= parity_index_reg + 8'd1;
end

always @(*) begin
    if (output_data_select == 1'b0)
        data_out = data_in;
    else
        data_out = lfsr_regs[2*t - 1 - parity_index_reg];
end




//========================= Generator Polynomial Function ========================
function [7:0] g;
input [4:0] addr;
begin
    case(addr)
        6'd0:  g = 8'd79;   // constant term x^0
        6'd1:  g = 8'd44;
        6'd2:  g = 8'd81;
        6'd3:  g = 8'd100;
        6'd4:  g = 8'd49;
        6'd5:  g = 8'd183;
        6'd6:  g = 8'd56;
        6'd7:  g = 8'd17;
        6'd8:  g = 8'd232;
        6'd9:  g = 8'd187;
        6'd10: g = 8'd126;
        6'd11: g = 8'd104;
        6'd12: g = 8'd31;
        6'd13: g = 8'd103;
        6'd14: g = 8'd52;
        6'd15: g = 8'd118;
        default: g = 8'd0;
    endcase
end
endfunction

endmodule