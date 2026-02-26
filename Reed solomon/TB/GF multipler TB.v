module tb_gf_multiplier_comb;

parameter m = 8;

reg  [m-1:0] op_a;
reg  [m-1:0] op_b;
wire [m-1:0] result;

gf_multiplier_comb #(.m(m)) dut (
    .op_a(op_a),
    .op_b(op_b),
    .result(result)
);

initial begin
    $display("GF(2^8) Combinational Multiplier Test");
    $display("=====================================");
    
    // Test 1: Multiply by 1
    op_a = 8'h53; op_b = 8'h01; #10;
    $display("0x%02h * 0x%02h = 0x%02h (expect 0x53)", op_a, op_b, result);
    
    // Test 2: Multiply by 0
    op_a = 8'h53; op_b = 8'h00; #10;
    $display("0x%02h * 0x%02h = 0x%02h (expect 0x00)", op_a, op_b, result);
    
    // Test 3: Known result (0x53 * 0xCA = 0x01 in AES GF)
    op_a = 8'h53; op_b = 8'hCA; #10;
    $display("0x%02h * 0x%02h = 0x%02h", op_a, op_b, result);
    
    // Test 4: Commutative
    op_a = 8'h57; op_b = 8'h83; #10;
    $display("0x%02h * 0x%02h = 0x%02h", op_a, op_b, result);
    
    op_a = 8'h83; op_b = 8'h57; #10;
    $display("0x%02h * 0x%02h = 0x%02h (should match above)", op_a, op_b, result);
    
    // Test 5: Square
    op_a = 8'h02; op_b = 8'h02; #10;
    $display("0x%02h * 0x%02h = 0x%02h (expect 0x04)", op_a, op_b, result);
    
    // Test 6: α * α^7 = α^8 = 0x1D (after reduction)
    op_a = 8'h02; op_b = 8'h80; #10;
    $display("0x%02h * 0x%02h = 0x%02h (expect 0x1D)", op_a, op_b, result);
    
    $display("=====================================");
    $finish;
end

endmodule