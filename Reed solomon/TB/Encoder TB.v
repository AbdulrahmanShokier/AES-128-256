`timescale 1ns/1ps

module tb_encoder_top;

parameter m = 8;
parameter k = 223;
parameter n = 255;
parameter t = 16;

// Signals
reg              clk;
reg              rst;
reg      [m-1:0] data_in;
reg              data_valid;
reg              start_encode;

wire     [m-1:0] data_out;
wire             data_out_valid;
wire             encoding_done;
wire             ready_for_data;
wire             buffer_is_full;
wire     [2:0]   current_state;

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 100 MHz
end

// DUT instantiation
encoder_top #(
    .m(m),
    .k(k),
    .n(n),
    .t(t)
) dut (
    .clk            (clk),
    .rst            (rst),
    .data_in        (data_in),
    .data_valid     (data_valid),
    .start_encode   (start_encode),
    .data_out       (data_out),
    .data_out_valid (data_out_valid),
    .encoding_done  (encoding_done),
    .ready_for_data (ready_for_data),
    .buffer_is_full (buffer_is_full),
    .current_state  (current_state)
);

// Output storage
reg [m-1:0] encoded_data [0:n-1];
integer output_idx;

// Test sequence
integer i;
initial begin
    // Initialize
    rst = 0;
    data_in = 0;
    data_valid = 0;
    start_encode = 0;
    output_idx = 0;
    
    // Reset
    #20;
    rst = 1;
    #20;
    
    // Start encoding
    $display("========================================");
    $display("Starting RS(%0d,%0d) Encoding", n, k);
    $display("========================================");
    
    start_encode = 1;
    @(posedge clk);
    start_encode = 0;
    
    // Wait for ready
    wait(ready_for_data);
    @(posedge clk);
    
    // Send k data symbols
    $display("Sending %0d data symbols...", k);
    for (i = 0; i < k; i = i + 1) begin
        data_in = i[7:0];  // Test pattern: 0, 1, 2, ..., k-1
        data_valid = 1;
        @(posedge clk);
    end
    data_valid = 0;
    
    $display("Data loading complete. Buffer full = %b", buffer_is_full);
    
    // Wait for output
    $display("Waiting for encoded output...");
    
    // Capture output
    output_idx = 0;
    while (!encoding_done) begin
        @(posedge clk);
        if (data_out_valid) begin
            encoded_data[output_idx] = data_out;
            output_idx = output_idx + 1;
        end
    end
    
    // Display results
    $display("========================================");
    $display("Encoding Complete!");
    $display("Total output symbols: %0d", output_idx);
    $display("========================================");
    
    // Display first few data symbols
    $display("First 10 data symbols:");
    for (i = 0; i < 10; i = i + 1) begin
        $display("  data_out[%3d] = 0x%02h", i, encoded_data[i]);
    end
    
    // Display parity symbols
    $display("Parity symbols (%0d total):", 2*t);
    for (i = k; i < n; i = i + 1) begin
        $display("  parity[%3d] = 0x%02h", i-k, encoded_data[i]);
    end
    
    $display("========================================");
    $display("Test Complete!");
    $display("========================================");
    
    #100;
    $finish;
end

// State monitor
always @(current_state) begin
    case (current_state)
        3'b000: $display("Time %0t: State = IDLE", $time);
        3'b001: $display("Time %0t: State = LOAD_DATA", $time);
        3'b010: $display("Time %0t: State = OUTPUT_DATA", $time);
        3'b011: $display("Time %0t: State = OUTPUT_PARITY", $time);
        default: $display("Time %0t: State = UNKNOWN", $time);
    endcase
end

// Timeout watchdog
initial begin
    #1000000;  // 1ms timeout
    $display("ERROR: Simulation timeout!");
    $finish;
end

endmodule