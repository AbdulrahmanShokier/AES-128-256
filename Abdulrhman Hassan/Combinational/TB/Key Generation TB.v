`timescale 1ns/1ps

module key_generator_tb;

    // Inputs
    reg  [127:0] key;

    // Outputs for each round
    wire [127:0] rk1, rk2, rk3, rk4, rk5, rk6, rk7, rk8, rk9, rk10;

    // Instantiate the 10 key generator modules sequentially
    key_generator R1 (.key(key),  .round_number(8'h01), .round_key(rk1));
    key_generator R2 (.key(rk1),  .round_number(8'h02), .round_key(rk2));
    key_generator R3 (.key(rk2),  .round_number(8'h04), .round_key(rk3));
    key_generator R4 (.key(rk3),  .round_number(8'h08), .round_key(rk4));
    key_generator R5 (.key(rk4),  .round_number(8'h10), .round_key(rk5));
    key_generator R6 (.key(rk5),  .round_number(8'h20), .round_key(rk6));
    key_generator R7 (.key(rk6),  .round_number(8'h40), .round_key(rk7));
    key_generator R8 (.key(rk7),  .round_number(8'h80), .round_key(rk8));
    key_generator R9 (.key(rk8),  .round_number(8'h1B), .round_key(rk9));
    key_generator R10(.key(rk9),  .round_number(8'h36), .round_key(rk10));

    initial begin
        // Initial Key (AES standard example)
        key = 128'h000102030405060708090a0b0c0d0e0f;

        #10;
        $display("==================================================");
        $display(" AES-128 KEY EXPANSION (10 ROUNDS) ");
        $display("==================================================");
        $display("Round 0 Key = %h", key);
        $display("--------------------------------------------------");
        $display("Round 1 Key = %h", rk1);
        $display("Expected    = D6AA74FDD2AF72FADAA678F1D6AB76FE");
        $display("--------------------------------------------------");
        $display("Round 2 Key = %h", rk2);
        $display("Expected    = B692CF0B643DBDF1BE9BC5006830B3FE");
        $display("--------------------------------------------------");
        $display("Round 3 Key = %h", rk3);
        $display("Expected    = B6FF744ED2C2C9BF6C590CBF0469BF41");
        $display("--------------------------------------------------");
        $display("Round 4 Key = %h", rk4);
        $display("Expected    = 47F7F7BC95353E03F96C32BCFD058DFD");
        $display("--------------------------------------------------");
        $display("Round 5 Key = %h", rk5);
        $display("Expected    = 3CAAA3E8A99F9DEAFB6F4DAD7C8DDAA9");
        $display("--------------------------------------------------");
        $display("Round 6 Key = %h", rk6);
        $display("Expected    = 5E390F7DF7A69296A7553DC10AA31F6B");
        $display("--------------------------------------------------");
        $display("Round 7 Key = %h", rk7);
        $display("Expected    = 14F9701AE35FE28C440ADF4D4EA9C026");
        $display("--------------------------------------------------");
        $display("Round 8 Key = %h", rk8);
        $display("Expected    = 47438735A41C65B9E016BAF4AEBF7AD2");
        $display("--------------------------------------------------");
        $display("Round 9 Key = %h", rk9);
        $display("Expected    = 549932D1F08557681093ED9CBE2C974E");
        $display("--------------------------------------------------");
        $display("Round 10 Key = %h", rk10);
        $display("Expected     = 13111D7FE3944A17F307A78B4D2B30C5");
        $display("==================================================");

        #10;
        $finish;
    end

endmodule
