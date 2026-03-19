module bpsk_upsampler #(
    parameter DATA_WIDTH      = 16,
    parameter Counter_WIDTH   = 2,
    parameter upsample_factor = 4
)
(
    input  wire                          clk_sample,
    input  wire                          rst,
    input  wire                          valid_in,
    input  wire signed [DATA_WIDTH-1:0]  data_in,
    output reg  signed [DATA_WIDTH-1:0]  data_out,
    output reg                           valid_out
);

reg [Counter_WIDTH : 0]       counter;
reg signed [DATA_WIDTH-1 : 0] data_in_reg;
reg                           valid_window;  

// ── Latch input symbol ───────────────────────────────────────────
always @(*) 
begin
    if (counter == 0)
        if(valid_in || valid_window)
            data_in_reg = data_in;
        else
            data_in_reg = {DATA_WIDTH{1'b0}};
end

// ── valid_window control ─────────────────────────────────────────

// to save the valid in of the current symbol and put it in valid out till the next symbol arrival
always @(*) 
begin
    if (!rst)
        valid_window = 1'b0;
    else 
    begin
        if (valid_in && counter == 0)          
            valid_window = 1'b1;              
        else if (counter == upsample_factor) // if the counter reach 4 (which is upsample factor) the window immidiatly return to zero  
            valid_window = 1'b0;              
    end
end

// ── Data output ──────────────────────────────────────────────────
always @(posedge clk_sample) 
begin
    if (!rst) 
    begin
        data_out  <= {DATA_WIDTH{1'b0}};
        valid_out <= 1'b0;
    end
    else 
    begin
        valid_out <= valid_window;             

        if (valid_window) 
        begin
            if (counter == 0)
                data_out <= data_in_reg;
            else
                data_out <= {DATA_WIDTH{1'b0}};
        end
    end
end

// ── Counter ──────────────────────────────────────────────────────
always @(posedge clk_sample) 
begin
    if (!rst)
        counter <= {Counter_WIDTH{1'b0}};

    else if(valid_in || valid_window)
    begin
        if(counter <= upsample_factor - 1)
            counter <= counter + 1;
        
        else
            counter <= {Counter_WIDTH{1'b0}};
    end

    else
        counter <= {Counter_WIDTH{1'b0}};    
end

endmodule