module Add_Round_Key 
(
    input      [127:0] plain_text,
    input      [127:0] key,
    output     [127:0] resultant_state_array
);

assign resultant_state_array = plain_text ^ key;

endmodule


// I made it sequential but chatgpt told me its better if it done combinational