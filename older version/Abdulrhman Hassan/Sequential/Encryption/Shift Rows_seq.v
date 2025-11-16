module shift_row
(
    input              clk,
    input              asy_reset,    
    input  [127:0] substituted_state_array,
    output [127:0] shifted_state_array
);


    always@(posedge clk or negedge asy_reset)
    begin
        if(!asy_reset)
        begin
            shifted_state_array <= 128'h0;
        end

        else 
        begin
            shifted_state_array <= temp_shifted_state_array ;

        end
    end



    // State bytes in column-major order
    wire [7:0] s [0:15];

    assign {s[0], s[1], s[2], s[3],
            s[4], s[5], s[6], s[7],
            s[8], s[9], s[10], s[11],
            s[12], s[13], s[14], s[15]} = substituted_state_array;


    reg [127:0] temp_shifted_state_array;


    // Perform AES ShiftRows
    assign temp_shifted_state_array = {
        // Column 0
        s[0],  s[5],  s[10], s[15],  
        // Column 1
        s[4],  s[9],  s[14], s[3],
        // Column 2
        s[8],  s[13], s[2],  s[7],
        // Column 3
        s[12], s[1],  s[6],  s[11]
    };

endmodule



/*

The standard FIPS-197 uses column-major, meaning:

State =
| b0   b4   b8   b12 |
| b1   b5   b9   b13 |
| b2   b6   b10  b14 |
| b3   b7   b11  b15 |
*/

// column major (اول 4 بايت بيكونو بالطول مش ب العرض) 
