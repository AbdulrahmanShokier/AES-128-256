`timescale 1ns / 1ps
// =============================================================================
// tb_rs_decoder.v  —  Testbench for RS(255,223) Decoder
//
// RS(255,223): n=255, k=223, t=16  (corrects up to 16 symbol errors)
//
// Test scenarios:
//   TEST 1 : All-zero codeword, 0 errors  →  clean pass, no decode_fail
//   TEST 2 : All-zero codeword, 5 errors  →  corrected, no decode_fail
//   TEST 3 : All-zero codeword, 16 errors →  corrected, no decode_fail (limit)
//   TEST 4 : All-zero codeword, 17 errors →  decode_fail expected
//
// The all-zero word is a valid RS codeword (linear code property).
// Injected errors are non-zero XOR masks at chosen byte positions.
// =============================================================================

module tb_rs_decoder;

    // =========================================================================
    // Parameters
    // =========================================================================
    localparam N   = 255;
    localparam K   = 223;
    localparam T   = 16;
    localparam CLK = 10;   // 10 ns  (100 MHz)

    // =========================================================================
    // DUT signals
    // =========================================================================
    reg        clk;
    reg        rst_n;
    reg  [7:0] rx_data;
    reg        rx_valid;
    wire [7:0] tx_data;
    wire       tx_valid;
    wire       decode_fail;
    wire       frame_done;

    // =========================================================================
    // DUT instantiation
    // =========================================================================
    rs_decoder_top #(.N(N), .K(K), .T(T), .T2(T*2)) dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .rx_data    (rx_data),
        .rx_valid   (rx_valid),
        .tx_data    (tx_data),
        .tx_valid   (tx_valid),
        .decode_fail(decode_fail),
        .frame_done (frame_done)
    );

    // =========================================================================
    // Clock
    // =========================================================================
    initial clk = 1'b0;
    always  #(CLK/2) clk = ~clk;

    // =========================================================================
    // Test infrastructure
    // =========================================================================
    integer pass_count, fail_count;

    reg [7:0] codeword [0:N-1];
    reg [7:0] expected [0:N-1];
    reg [7:0] received [0:N-1];

    // ---- Build all-zero codeword ----
    task build_zero_codeword;
        integer k;
        begin
            for (k = 0; k < N; k = k + 1) begin
                codeword[k] = 8'h00;
                expected[k] = 8'h00;
            end
        end
    endtask

    // ---- Inject a single-byte error ----
    task inject_error;
        input [7:0] pos;
        input [7:0] mask;
        begin
            codeword[pos] = codeword[pos] ^ mask;
            // expected output remains 8'h00 (decoder should correct it)
        end
    endtask

    // ---- Clock in all N bytes ----
    task send_frame;
        integer k;
        begin
            @(posedge clk);
            for (k = 0; k < N; k = k + 1) begin
                @(negedge clk);
                rx_data  = codeword[k];
                rx_valid = 1'b1;
                @(posedge clk);
            end
            @(negedge clk);
            rx_valid = 1'b0;
            rx_data  = 8'h00;
        end
    endtask

    // ---- Collect N output bytes ----
    task collect_output;
        integer k;
        begin
            k = 0;
            while (k < N) begin
                @(posedge clk);
                if (tx_valid) begin
                    received[k] = tx_data;
                    k = k + 1;
                end
            end
        end
    endtask

    // ---- Wait for frame_done ----
    task wait_frame_done;
        begin
            // Check if it's already high before waiting!
            if (!frame_done) @(posedge frame_done);
            
            @(posedge clk);
        end
    endtask

    // ---- Check and report ----
    task check_result;
        input [255:0] tname;
        input         expect_fail;
        integer       k, mismatches;
        begin
            mismatches = 0;
            if (expect_fail) begin
                if (decode_fail) begin
                    $display("[PASS] %s  decode_fail correctly asserted.", tname);
                    pass_count = pass_count + 1;
                end else begin
                    $display("[FAIL] %s  decode_fail NOT asserted (expected).", tname);
                    fail_count = fail_count + 1;
                end
            end else begin
                if (decode_fail) begin
                    $display("[FAIL] %s  unexpected decode_fail.", tname);
                    fail_count = fail_count + 1;
                end else begin
                    for (k = 0; k < N; k = k + 1) begin
                        if (received[k] !== expected[k]) begin
                            $display("       byte[%3d] : got 0x%02h, expected 0x%02h",
                                     k, received[k], expected[k]);
                            mismatches = mismatches + 1;
                        end
                    end
                    if (mismatches == 0) begin
                        $display("[PASS] %s  all %0d bytes correct.", tname, N);
                        pass_count = pass_count + 1;
                    end else begin
                        $display("[FAIL] %s  %0d byte mismatch(es).", tname, mismatches);
                        fail_count = fail_count + 1;
                    end
                end
            end
        end
    endtask

    // ---- Full test runner ----
    task run_test;
        input [255:0] tname;
        input         expect_fail;
        begin
            $display("\n--- %s ---", tname);
            @(negedge clk); rst_n = 1'b0;
            repeat(4) @(posedge clk);
            @(negedge clk); rst_n = 1'b1;
            repeat(2) @(posedge clk);

            fork
                send_frame;
                collect_output;
                wait_frame_done;
            join

            check_result(tname, expect_fail);
        end
    endtask

    // =========================================================================
    // Test sequence
    // =========================================================================
    initial begin
        clk      = 1'b0;
        rst_n    = 1'b0;
        rx_data  = 8'h00;
        rx_valid = 1'b0;
        pass_count = 0;
        fail_count = 0;

        repeat(4) @(posedge clk);
        rst_n = 1'b1;
        repeat(4) @(posedge clk);

        // =====================================================================
        // TEST 1 : zero errors
        // =====================================================================
        build_zero_codeword;
        run_test("TEST1: no errors                      ", 1'b0);

        // =====================================================================
        // TEST 2 : 5 errors (well within t=16)
        // =====================================================================
        build_zero_codeword;
        inject_error(8'd7,   8'hAB);
        inject_error(8'd33,  8'h5C);
        inject_error(8'd99,  8'hFF);
        inject_error(8'd180, 8'h12);
        inject_error(8'd250, 8'hE3);
        run_test("TEST2: 5 errors (pos 7,33,99,180,250) ", 1'b0);

        // =====================================================================
        // TEST 3 : 16 errors (exactly at the t=16 limit)
        // =====================================================================
        build_zero_codeword;
        inject_error(8'd0,   8'h11);
        inject_error(8'd15,  8'h22);
        inject_error(8'd30,  8'h33);
        inject_error(8'd45,  8'h44);
        inject_error(8'd60,  8'h55);
        inject_error(8'd75,  8'h66);
        inject_error(8'd90,  8'h77);
        inject_error(8'd105, 8'h88);
        inject_error(8'd120, 8'h99);
        inject_error(8'd135, 8'hAA);
        inject_error(8'd150, 8'hBB);
        inject_error(8'd165, 8'hCC);
        inject_error(8'd180, 8'hDD);
        inject_error(8'd195, 8'hEE);
        inject_error(8'd210, 8'hA5);
        inject_error(8'd254, 8'h5A);
        run_test("TEST3: 16 errors (limit t=16)         ", 1'b0);

        // =====================================================================
        // TEST 4 : 17 errors (exceeds t=16; decode_fail expected)
        // =====================================================================
        build_zero_codeword;
        inject_error(8'd1,   8'h01);  inject_error(8'd2,  8'h02);
        inject_error(8'd3,   8'h03);  inject_error(8'd4,  8'h04);
        inject_error(8'd5,   8'h05);  inject_error(8'd6,  8'h06);
        inject_error(8'd7,   8'h07);  inject_error(8'd8,  8'h08);
        inject_error(8'd9,   8'h09);  inject_error(8'd10, 8'h0A);
        inject_error(8'd11,  8'h0B);  inject_error(8'd12, 8'h0C);
        inject_error(8'd13,  8'h0D);  inject_error(8'd14, 8'h0E);
        inject_error(8'd15,  8'h0F);  inject_error(8'd16, 8'h10);
        inject_error(8'd17,  8'h11);  // 17th error
        run_test("TEST4: 17 errors (>t=16, expect fail) ", 1'b1);

        // =====================================================================
        // Summary
        // =====================================================================
        $display("\n============================================");
        $display("  RS(255,223)  Results: %0d PASSED / %0d FAILED",
                 pass_count, fail_count);
        $display("============================================\n");

        if (fail_count == 0) $display("ALL TESTS PASSED");
        else                 $display("SOME TESTS FAILED — inspect waveforms");

        $finish;
    end

    // =========================================================================
    // Watchdog
    // =========================================================================
    initial begin
        #(CLK * 150_000);
        $display("[TIMEOUT] Simulation exceeded 150 000 cycles.");
        $finish;
    end

    // =========================================================================
    // Waveform dump
    // =========================================================================
    initial begin
        $dumpfile("rs_decoder_255_223.vcd");
        $dumpvars(0, tb_rs_decoder);
    end

endmodule
