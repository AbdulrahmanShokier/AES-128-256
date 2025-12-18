module key_generator_dec #(parameter BLOCK_LENGTH = 128)
(   
    input      clk,
    input      rst,
    input      en,                   // Enable signal from the FSM 
    input      [BLOCK_LENGTH-1:0] key,
    input      [3:0] Round_Count,
    output reg [1407:0] keys // 11 registers to store all the keys once calculated

);


///////////////////////////////////////////Wires and Registers////////////////////////////////////////////


wire [31:0] w0, w1, w2, w3;
wire [31:0] g_out;
wire [31:0] w4, w5, w6, w7;


wire [7 : 0] Round_Const_in_gfunc; // round number used in g-func 

reg [7 : 0] Round_Const;

wire [BLOCK_LENGTH-1:0] next_round_key;


//////////////////////////////////////////////////////////////////////////////////////////////////////////

assign w0 = keys[1407 : 1376] ;
assign w1 = keys[1375 : 1344] ;
assign w2 = keys[1343 : 1312] ;
assign w3 = keys[1311 : 1280] ;


g_function g_func (.word_3(w3), .round_number(Round_Const_in_gfunc), .word_3_substituted(g_out));


assign w4 = w0 ^ g_out ;
assign w5 = w1 ^ w4    ;
assign w6 = w2 ^ w5    ;
assign w7 = w3 ^ w6    ;


assign next_round_key = {w4, w5, w6, w7};



always@(negedge rst or posedge clk)
begin

    if(!rst)
    begin
    keys  <= 1408'b0;  
    end

    else if(en)  
    begin

    if(Round_Count == 4'b0)
    begin
        keys[1407:1280] <= key;      // first key
    end

    if(Round_Count > 4'b0 && Round_Count < 4'd11)
     begin
        keys            <= keys >> 8'b10000000; // to shift the key to make a space for the next key 
        keys[1407:1280] <= next_round_key;      // put the next key in the MSB 128 bits
     end

    end

    else
    begin
     keys <= keys  ; 
    end

end



///////////////////////// to calculate the polynomial round number of the decimal counter////////////////////

always@(*)
begin 
 case(Round_Count)
 4'd1:  Round_Const = 8'h1; 
 4'd2:  Round_Const = 8'h2; 
 4'd3:  Round_Const = 8'h4; 
 4'd4:  Round_Const = 8'h8; 
 4'd5:  Round_Const = 8'h10; 
 4'd6:  Round_Const = 8'h20; 
 4'd7:  Round_Const = 8'h40; 
 4'd8:  Round_Const = 8'h80; 
 4'd9:  Round_Const = 8'h1B; 
 4'd10: Round_Const = 8'h36; 
 default: Round_Const = 8'h0; 
 endcase
end

assign Round_Const_in_gfunc = Round_Const;


endmodule



//k10 is on the MSB and k0 is on LSB