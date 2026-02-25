module RC_adder (
    input wire [7:0] byte_in,
    input wire [3:0] round_number,
    //input wire [7:0] round_counter_polynomial,
    output wire [7:0] byte_out
);
    // Add the round constant to the input byte
    reg [7:0] round_counter_polynomial;

//we could do this but Round counter values are fixed so we can use assign statements directly
// or we can do this MUX

    always @(*) begin
        case (round_number)
            4'd1: round_counter_polynomial = 8'h01;
            4'd2: round_counter_polynomial = 8'h02;
            4'd3: round_counter_polynomial = 8'h04;
            4'd4: round_counter_polynomial = 8'h08;
            4'd5: round_counter_polynomial = 8'h10;
            4'd6: round_counter_polynomial = 8'h20;
            4'd7: round_counter_polynomial = 8'h40;
            4'd8: round_counter_polynomial = 8'h80;
            4'd9: round_counter_polynomial = 8'h1B;
            4'd10: round_counter_polynomial = 8'h36;
            default: round_counter_polynomial = 8'h00;
        endcase
    end

    assign byte_out = byte_in ^ round_counter_polynomial;


endmodule; //RC_adder