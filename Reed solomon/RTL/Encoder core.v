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
            .op_a(feedback),
            .op_b(g(g_idx)),
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


// always @(posedge clk)
// begin
//     if (!rst)
//         data_out <= 8'b0;

//     else 
//     begin
//         if (output_data_select == 1'b0)
//             data_out <= data_in;
//         else
//             data_out <= lfsr_regs[2*t - 1 - parity_index_reg];
//     end
// end

//========================= Generator Polynomial Function ========================
function [7:0] g;
input [5:0] addr;
begin
    case(addr)
        6'd0:  g = 8'd45;   // constant term x^0
        6'd1:  g = 8'd216;
        6'd2:  g = 8'd239;
        6'd3:  g = 8'd24;
        6'd4:  g = 8'd253;
        6'd5:  g = 8'd104;
        6'd6:  g = 8'd27;
        6'd7:  g = 8'd40;
        6'd8:  g = 8'd107;
        6'd9:  g = 8'd50;
        6'd10: g = 8'd163;
        6'd11: g = 8'd210;
        6'd12: g = 8'd227;
        6'd13: g = 8'd134;
        6'd14: g = 8'd224;
        6'd15: g = 8'd158;
        6'd16: g = 8'd119;
        6'd17: g = 8'd13;
        6'd18: g = 8'd158;
        6'd19: g = 8'd1;
        6'd20: g = 8'd238;
        6'd21: g = 8'd164;
        6'd22: g = 8'd82;
        6'd23: g = 8'd43;
        6'd24: g = 8'd15;
        6'd25: g = 8'd232;
        6'd26: g = 8'd246;
        6'd27: g = 8'd142;
        6'd28: g = 8'd50;
        6'd29: g = 8'd189;
        6'd30: g = 8'd29;
        6'd31: g = 8'd232;  // x^31 coefficient
        default: g = 8'd0;
    endcase
end
endfunction

endmodule