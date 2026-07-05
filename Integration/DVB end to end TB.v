`timescale 1ns/1ps

module DVB_end_to_end_top_tb;

    //------------------------------------------------------------
    // Parameters
    //------------------------------------------------------------
    localparam BLOCK_LENGTH = 128;
    localparam CONTROL_WIDTH = 256;

    //------------------------------------------------------------
    // DUT Inputs
    //------------------------------------------------------------
    reg clk;
    reg rst;
    reg sof;

    reg [BLOCK_LENGTH-1:0] plaintext_in;
    reg [BLOCK_LENGTH-1:0] aes_key;

    //------------------------------------------------------------
    // DUT Outputs
    //------------------------------------------------------------
    wire [CONTROL_WIDTH-1:0] Control_register;
    wire                     Control_complete;

    wire [127:0] aes_dec_out;
    wire         aes_dec_valid;

    wire [3:0] period_count_o;
    wire [2:0] rs_current_state_o;

    //------------------------------------------------------------
    // Instantiate DUT
    //------------------------------------------------------------
     //------------------------------------------------------------
    // Instantiate DUT
    //------------------------------------------------------------
    DVB_end_to_end_top #(
        .BLOCK_LENGTH(BLOCK_LENGTH),

        // Reed-Solomon parameters
        .RS_M(8),
        .RS_K(192),
        .RS_N(208),
        .RS_T(8),

        // Frame parameters
        .PREAMBLE_WIDTH(255),
        .CONTROL_WIDTH(CONTROL_WIDTH),

        .PREAMBLE_COUNTER_WIDTH(8),
        .CONTROL_COUNTER_WIDTH(8),
        .aes_word_counter_width(9),
        .crc_counter_width(5),

        .aes_word_count(1),
        .crc_width(32),

        .dummy_width(40),
        .dummy_counter_width(6),

        // Receiver
        .DATA_WIDTH(16)
    ) dut (
        .clk(clk),
        .rst(rst),

        .sof(sof),

        .plaintext_in(plaintext_in),
        .aes_key(aes_key),

        .Control_register(Control_register),
        .Control_complete(Control_complete),

        .aes_dec_out(aes_dec_out),
        .aes_dec_valid(aes_dec_valid),

        .period_count_o(period_count_o),
        .rs_current_state_o(rs_current_state_o)
    );
    //------------------------------------------------------------
    // Clock Generation (100 MHz)
    //------------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //------------------------------------------------------------
    // Stimulus
    //------------------------------------------------------------
    initial begin

        // Initialize
        rst = 0;          // Active-low reset asserted
        sof = 0;

        plaintext_in = 128'h00112233445566778899AABBCCDDEEFF;
        aes_key      = 128'h000102030405060708090A0B0C0D0E0F;

        //--------------------------------------------------------
        // Hold reset
        //--------------------------------------------------------
        repeat (10) @(posedge clk);

        rst = 1;          // Release reset

        repeat (4) @(posedge clk);

        //--------------------------------------------------------
        // Start one frame
        //--------------------------------------------------------
        sof = 1;
        @(posedge clk);
        sof = 0;

        //--------------------------------------------------------
        // Wait long enough for the complete TX/RX chain
        //--------------------------------------------------------
        repeat (10000) @(posedge clk);

        $display("----------------------------------------");
        $display("Simulation Finished");
        $display("----------------------------------------");

        $finish;
    end

    //------------------------------------------------------------
    // Monitor decrypted data
    //------------------------------------------------------------
    always @(posedge clk) begin
        if (aes_dec_valid) begin
            $display("[%0t ns]", $time);
            $display("AES Decrypted Data = %032h", aes_dec_out);

            if (aes_dec_out == plaintext_in)
                $display("PASS : Decrypted data matches plaintext.\n");
            else begin
                $display("FAIL : Decrypted data mismatch.");
                $display("Expected = %032h", plaintext_in);
                $display("Received = %032h\n", aes_dec_out);
            end
        end
    end

    //------------------------------------------------------------
    // Optional waveform dump
    //------------------------------------------------------------
    initial begin
        $dumpfile("DVB_end_to_end.vcd");
        $dumpvars(0, DVB_end_to_end_top_tb);
    end

endmodule