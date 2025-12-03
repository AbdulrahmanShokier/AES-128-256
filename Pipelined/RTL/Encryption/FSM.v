module FSM(
    input            clk,
    input            rst,
    input            fsm_en,
    output reg       key_gene_en,
    output reg [3:0] Round_Count
);

reg [3:0] counter_value;


parameter [1:0]
idle    = 2'b00;
counter = 2'b01;
hold    = 2'b10;


reg [1:0] current_state,next_state;

always@(posedge clk or negedge rst)
begin
    if(!rst)
    begin
        current_state <= idle;
    end
    
    else
    begin
        current_state <= next_state;
    end

end


always@(current_state or fsm_en)
begin
    case(current_state)
    
    idle:
    begin
        counter_value = 1'b0;
        key_gene_en   = 1'b0;
        if(fsm_en)
        next_state = counter;
        else
        next_state = idle;
    end

    counter:
    begin
        if(counter_value < 4'b11)
        begin
            next_state    = counter;
            counter_value = counter_value + 1'b1 ;
            key_gene_en   = 1'b1;
        end

        else if(counter_value == 4'b11)
        begin
            next_state    = hold;
            key_gene_en   = 1'b0;
        end
    end
    
    hold:
        if(!rst)
        begin
            next_state = idle;
        end

        else
        begin
            next_state = hold;
        end

        default:
            next_state = idle;

    endcase
end



endmodule