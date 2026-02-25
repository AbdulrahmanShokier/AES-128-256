module encoder_core
#(
    parameter m = 8,    // symbol size in bits (GF[2^m])
    parameter k = 223,    // no. of symbols   (data)
    parameter n = 255,    // code word length (data + parity)
    parameter t = 16      // no. of symbols can corrected  
)
(
    input              clk,
    input              rst,
    input      [m-1:0] data_in,
    input              data_valid,
    input              start_encode,
    output reg [m-1:0] data_buffer [0:k-1],
    output reg         buffer_is_full
);

reg [7:0] counter;


reg  [m-1 : 0] lfsr_regs [0 : 2*t-1];
wire [m-1:0] feedback;

//===================================== Counter ==========================================
/*
always block for counter, as long as the data_valid flag are high the counter will keep
incrementing till it reaches the number of symbols, it resetes on a rst signal or the 
buffer_is_full flag which means the buffer is full and it is waiting to start the encoding process
*/

always@(posedge clk)
begin
    if(!rst || start_encode)
    begin
        counter <= 8'b0;
        buffer_is_full <= 1'b0;
    end

    else if (data_valid && (counter < k) )
    begin
    
        if(counter == k-1 )
            buffer_is_full <= 1'b1;
        else 
            buffer_is_full <= 1'b0;

        counter <= counter + 1;
    end
    
    else
        counter <= counter; 
end



//==================================== buffer in-loading ====================================

always@(posedge clk)
begin
    if (data_valid && counter < k)
    begin
        data_buffer[counter] <= data_in;  
    end
    
    else 
        data_buffer <= data_buffer;

end

//======================================= encoding =======================================

assign feedback = data_in ^ lfsr_regs[2*t-1]; 


endmodule