
module FSM_controller (
    input wire clk,
    input wire rst_n,
    input wire vaild_in,
    input wire [127:0] key_in,
    output wire vaild_out, // P.T. is ready 
    output wire [3:0] round_count_to_keyExp, // for testing purpose
    output wire [127:0] KeyOut_KeyExpLoad, //data that will be loaded into Key Expansion Module
    input wire [127:0] KeyExp_RoundKey, // Round key from the key expansion module output
    output reg [1:0] KeyExp_control, // 01 load 10 forward 11 reverse 
    output wire Decryptor_en// Enable signal for the AES Decryptor

);

    localparam IDLE     = 2'b00; // Waiting for valid input
    localparam K10_CALC  = 2'b01; // New key detected, calculate round 0 key
    localparam DECRYPT  = 2'b10; // Decryption is in progress
    

    



    // --- Internal Registers and Wires ---
    reg [1:0] current_state; 
    reg [1:0] next_state; // Wire for the combinational next state output

    wire if_key_same;

    reg [3:0] round_counter; // Counter for tracking decryption rounds

    // Buffers for storing the current key and its derived round 0 key
    reg [127:0] ChiperKey_buffer;   // Stores the *last used* ChiperKey
    reg [127:0] key10_dec_buffer;    // Stores the *last calculated* Decryption Round 0 Key
    
    // --- Key Comparison Logic ---
    assign if_key_same = (ChiperKey_buffer == key_in);


    //--- Decryptior enable logic ---

    // nomral case make the Decryptor wait for the Key expashion to get K10

    assign Decryptor_en = (current_state == DECRYPT) ? 1'b1 : 1'b0;


    // --- Vaild Out Flag Logic ---
    reg vaild_outFlag_ff;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vaild_outFlag_ff <= 1'b0;
        end else begin
            vaild_outFlag_ff <= (current_state == DECRYPT && round_counter == 4'd0000);
        end
    end

    assign vaild_out = vaild_outFlag_ff;





     // --- Key Buffer Logic -------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ChiperKey_buffer <= 128'b0;
            key10_dec_buffer <= 128'b0;
        end else begin
            if (current_state == DECRYPT && round_counter== 4'd10) begin
                key10_dec_buffer <= KeyExp_RoundKey;
            end else begin
                key10_dec_buffer <= key10_dec_buffer;
            end

            if (vaild_in) begin
                ChiperKey_buffer <= key_in; 
            end 
            else begin
                ChiperKey_buffer <= ChiperKey_buffer;
            end
        end
    end
    

    assign KeyOut_KeyExpLoad = (if_key_same) ? key10_dec_buffer : key_in;


    // --- State Register (Sequential Logic) ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE; // Initial state
        end else begin
            current_state <= next_state;
        end  
    end


    // --- Round Counter Logic ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) round_counter <= 4'b0001;
        else  begin
            if(current_state == IDLE) begin
                if(if_key_same) round_counter <= 4'd10;
                else round_counter <= 4'b0001;
            end
            else if (current_state == K10_CALC && round_counter != 4'd10) round_counter <= round_counter + 4'd1; // in key expansion we need roundcounter=10 to get round key 9
            else if (current_state == DECRYPT) round_counter <= round_counter - 4'd1;
            else round_counter <= round_counter;
        end
    end

    // --- Next State Logic (Combinational) ---
    always @(*)begin
        case(current_state)
            IDLE: begin
                if (vaild_in) begin
                    if (if_key_same) begin
                        next_state = DECRYPT;
                    end 
                    else begin
                        next_state = K10_CALC;
                    end
                end else begin
                    next_state = IDLE;
                end
            end

            K10_CALC: next_state = (round_counter == 4'd10) ? DECRYPT : K10_CALC;
                
            DECRYPT: next_state = (round_counter == 4'b0000) ? IDLE : DECRYPT;
                
            default: next_state = IDLE;
        endcase
    end


    
    // key expansion control logic
    always @(*) begin
        case(current_state)
            IDLE: begin
                KeyExp_control = 2'b01; // load key
            end

            K10_CALC: begin
                KeyExp_control = 2'b10; // forward key expansion
            end

            DECRYPT: begin
               KeyExp_control = 2'b11; // reverse key expansion
            end

            default: begin
                KeyExp_control = 2'b00; 
            end
        endcase
    end

    wire [3:0]round_count_diplay;
    assign round_count_diplay = round_counter;
    assign round_count_to_keyExp = round_counter;
    

    

endmodule // FSM_controller.v
