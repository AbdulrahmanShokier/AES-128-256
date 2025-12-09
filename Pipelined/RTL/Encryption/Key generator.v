module key_generator #(parameter BLOCK_LENGTH = 128)
(   
    input      clk,
    input      rst,
    input      en,                   // Enable signal from the FSM 
    input      [BLOCK_LENGTH-1:0] key,
    input      [3:0] Round_Count,

    output reg [BLOCK_LENGTH-1:0] k0, 
    output reg [BLOCK_LENGTH-1:0] k1,
    output reg [BLOCK_LENGTH-1:0] k2,
    output reg [BLOCK_LENGTH-1:0] k3,
    output reg [BLOCK_LENGTH-1:0] k4,
    output reg [BLOCK_LENGTH-1:0] k5,
    output reg [BLOCK_LENGTH-1:0] k6,
    output reg [BLOCK_LENGTH-1:0] k7,
    output reg [BLOCK_LENGTH-1:0] k8,
    output reg [BLOCK_LENGTH-1:0] k9,
    output reg [BLOCK_LENGTH-1:0] k10 // 11 registers to store all the keys once calculated
);


///////////////////////////////////////////Wires and Registers////////////////////////////////////////////


wire [31:0] w0, w1, w2, w3;
wire [31:0] g_out;
wire [31:0] w4, w5, w6, w7;


wire [7 : 0] Round_Const_in_gfunc; // round number used in g-func 

reg [7 : 0] Round_Const;

reg [BLOCK_LENGTH-1:0] round_key;

wire [BLOCK_LENGTH-1:0] next_round_key;


//////////////////////////////////////////////////////////////////////////////////////////////////////////


always@(*)
begin 
    case(Round_Count)
    4'd0:  round_key = key;        // first key
    4'd1:  round_key = k0;
    4'd2:  round_key = k1;
    4'd3:  round_key = k2;
    4'd4:  round_key = k3;
    4'd5:  round_key = k4;
    4'd6:  round_key = k5;
    4'd7:  round_key = k6;
    4'd8:  round_key = k7; 
    4'd9:  round_key = k8; 
    4'd10: round_key = k9;
    endcase   
end


assign w0 = round_key[127 : 96] ;
assign w1 = round_key[ 95 : 64] ;
assign w2 = round_key[ 63 : 32] ;
assign w3 = round_key[ 31 : 0 ] ;


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
     k0  <= 128'b0; 
     k1  <= 128'b0; 
     k2  <= 128'b0; 
     k3  <= 128'b0; 
     k4  <= 128'b0; 
     k5  <= 128'b0; 
     k6  <= 128'b0; 
     k7  <= 128'b0; 
     k8  <= 128'b0;  
     k9  <= 128'b0;  
     k10 <= 128'b0; 
    end

    else if(en)  
    begin
    k0  <= key;        // first key
    case(Round_Count)
    4'd1:  k1  <= next_round_key;
    4'd2:  k2  <= next_round_key;
    4'd3:  k3  <= next_round_key;
    4'd4:  k4  <= next_round_key;
    4'd5:  k5  <= next_round_key;
    4'd6:  k6  <= next_round_key;
    4'd7:  k7  <= next_round_key;
    4'd8:  k8  <= next_round_key; 
    4'd9:  k9  <= next_round_key; 
    4'd10: k10 <= next_round_key;
    endcase 
    end

    else
    begin
     k0  <= k0  ; 
     k1  <= k1  ; 
     k2  <= k2  ; 
     k3  <= k3  ; 
     k4  <= k4  ; 
     k5  <= k5  ; 
     k6  <= k6  ; 
     k7  <= k7  ; 
     k8  <= k8  ;  
     k9  <= k9  ;  
     k10 <= k10 ; 
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