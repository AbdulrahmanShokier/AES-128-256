module FSM(
    input            clk,
    input            rst,
    input            fsm_en,
    output reg       key_gene_en,
    output reg [3:0] Round_Count
);

reg [3:0] counter_value;

parameter [1:0]
idle    = 2'b00,
counter = 2'b01,
hold    = 2'b10;

reg [1:0] current_state, next_state;


always @(posedge clk or negedge rst) 
begin
    if(!rst)
        current_state <= idle;
    else
        current_state <= next_state;
end


//////////////////////////////
//   OUTPUT + COUNTER LOGIC
//////////////////////////////
always @(posedge clk or negedge rst) 
begin
    if(!rst) 
    begin
        counter_value <= 4'd0;
        Round_Count   <= 4'd0;
        key_gene_en   <= 1'b0;
    end 
    
    else 
    begin
        case(next_state)
            idle: 
            begin
                counter_value <= 4'd0;
                Round_Count   <= 4'd0;
                key_gene_en   <= 1'b0;
            end

            counter: 
            begin
                if(current_state != counter) 
                begin
                    counter_value <= 4'd0;
                    Round_Count   <= 4'd0;
                    key_gene_en   <= 1'b1;
                end

                else 
                begin
                    counter_value <= counter_value + 1'b1;
                    Round_Count   <= counter_value + 1'b1;
                    key_gene_en   <= 1'b1;
                end
            end

            hold:
            begin
                counter_value <= 4'd0;
                Round_Count   <= 4'd0;
                key_gene_en   <= 1'b0;
            end

        endcase
    end
end


always @(*) 
begin
    case(current_state)

        idle:
            if(fsm_en)
                next_state = counter;
            else
                next_state = idle;

        counter:
            if(counter_value == 4'd11)
                next_state = hold;
            else
                next_state = counter;

        hold:
            if(!rst)
                next_state = idle;
            else if(fsm_en)
                next_state = counter;
            else
                next_state = hold;

        default:
            next_state = idle;

    endcase
end

endmodule
