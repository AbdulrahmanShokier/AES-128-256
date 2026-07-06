module aes_rs_reg #(
    parameter IN_WIDTH    = 128,
    parameter REG_WIDTH   = 128,
    parameter OUT_WIDTH   = 8,
    parameter COUNT_WIDTH = 4
)
(
    input  wire                    clk,
    input  wire                    rst,
    input  wire                    symbol_tick,
    input  wire                    load,        // AES output is valid, capture it
    input  wire [IN_WIDTH-1:0]     data_in,
    output reg  [OUT_WIDTH-1:0]    data_out
);

reg [REG_WIDTH-1:0]   data_reg;
reg [COUNT_WIDTH-1:0] counter;

always @(posedge clk) begin
    if (!rst) begin
        data_reg <= {REG_WIDTH{1'b0}};
        counter  <= {COUNT_WIDTH{1'b0}};
    end
    else if (symbol_tick) begin
        if (load) begin
            data_reg <= data_in;
            counter  <= {COUNT_WIDTH{1'b0}};   // restart byte index for the new word
        end
        else if (counter != {COUNT_WIDTH{1'b1}}) begin
            counter <= counter + 1'b1;          // advance through the 16 bytes
        end
        // else: counter == 15, hold until next load
    end
end

always @(posedge clk) begin
    if (!rst)
        data_out <= {OUT_WIDTH{1'b0}};
    else if (symbol_tick) begin
        if (load)
            data_out <= data_in[7:0];           // byte 0 of the NEW word, same fix as before
        else
            case (counter)
                4'd00 : data_out <= data_reg[15:8]    ;
                4'd01 : data_out <= data_reg[23:16]   ;
                4'd02 : data_out <= data_reg[31:24]   ;
                4'd03 : data_out <= data_reg[39:32]   ;
                4'd04 : data_out <= data_reg[47:40]   ;
                4'd05 : data_out <= data_reg[55:48]   ;
                4'd06 : data_out <= data_reg[63:56]   ;
                4'd07 : data_out <= data_reg[71:64]   ;
                4'd08 : data_out <= data_reg[79:72]   ;
                4'd09 : data_out <= data_reg[87:80]   ;
                4'd10 : data_out <= data_reg[95:88]   ;
                4'd11 : data_out <= data_reg[103:96]  ;
                4'd12 : data_out <= data_reg[111:104] ;
                4'd13 : data_out <= data_reg[119:112] ;
                4'd14 : data_out <= data_reg[127:120] ;
                default: data_out <= data_out;       // counter==0 but no load: hold (idle between words)
            endcase
    end
end

endmodule