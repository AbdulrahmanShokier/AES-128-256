module sub_bytes 
(
    input  [127:0] inverse_shifted_state_array,
    output [127:0] inverse_substituted_state_array
);

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : inverse_sbox_loop
            inverse_s_box s_inst (
                .in_byte(inverse_shifted_state_array[i*8 +: 8]),
                .out_byte(inverse_substituted_state_array[i*8 +: 8])
            );
        end
    endgenerate

endmodule

// i couldn't think in a way to make the s box and the module in th same file
//(عشان في الفريلوج متعرفش تعمل اراي فيها قيم ثابتة الكلام ده في السيستم فريلوج بس)
