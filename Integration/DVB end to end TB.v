`timescale 1ns/1ps

module DVB_end_to_end_top_tb;

    //------------------------------------------------------------
    // Parameters
    //------------------------------------------------------------
    localparam BLOCK_LENGTH   = 128;
    localparam CONTROL_WIDTH  = 256;
    localparam CLOCKS_PER_NEW_BLOCK = 128; // 32 symbol_ticks * 4 clk/tick
    localparam NUM_BLOCKS     = 51;        // only insert 12 AES blocks total

    // New: delay (in clocks, counted from reset release) before
    // block insertion/streaming is allowed to begin
    localparam INSERTION_START_DELAY = 2162;

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
    // Bookkeeping for streamed inputs
    //------------------------------------------------------------
    integer clk_counter;
    integer block_index;

    // New: free-running counter (since reset release) used to
    // gate when insertion is allowed to start, plus a latched
    // "go" flag once the delay has elapsed
    reg [31:0] global_clk_counter;
    reg        insertion_active;

    reg [16:0] sample_counter;

    always @(posedge clk) begin
        if (!rst)
            sample_counter <= 17'd0;
        else
            sample_counter <= sample_counter + 17'b1;
    end

    //------------------------------------------------------------
    // Global clock counter + insertion-start gate
    //------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst) begin
            global_clk_counter <= 32'd0;
            insertion_active   <= 1'b0;
        end
        else begin
            global_clk_counter <= global_clk_counter + 32'd1;

            if (global_clk_counter == INSERTION_START_DELAY)
                insertion_active <= 1'b1;
        end
    end

    // Precomputed distinct blocks, so you can see exactly what's
    // driven each time (visible in the waveform as plaintext_in changes)
    reg [BLOCK_LENGTH-1:0] block_array [0:NUM_BLOCKS-1];
    integer i;

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

        .aes_word_count(4),
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
    // Precompute 12 distinct blocks up front (avoids any function-
    // call / race issues that caused the same value to repeat)
    //------------------------------------------------------------
    initial begin
        for (i = 0; i < NUM_BLOCKS; i = i + 1) begin
            block_array[i] = 128'h00112233445566778899AABBCCDDEEFF + (i * 128'h1);
        end
    end

    // Edge-detect for insertion_active, so we can catch the exact
    // cycle the gate opens and avoid re-sending block 0 (it was
    // already sitting on plaintext_in, and effectively consumed,
    // for the whole hold period).
    reg insertion_active_d;

    always @(posedge clk) begin
        if (!rst)
            insertion_active_d <= 1'b0;
        else
            insertion_active_d <= insertion_active;
    end

    wire insertion_just_started = insertion_active && !insertion_active_d;

    //------------------------------------------------------------
    // Load counter: new plaintext block every CLOCKS_PER_NEW_BLOCK
    // clocks, but only once insertion_active is asserted (i.e.
    // after INSERTION_START_DELAY clocks from reset release).
    // Stops once NUM_BLOCKS have been loaded.
    //------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst) begin
            clk_counter  <= 0;
            block_index  <= 0;
            plaintext_in <= block_array[0];
        end
        else if (!insertion_active) begin
            // Hold steady on the first block until the insertion
            // window opens; nothing streams yet.
            clk_counter  <= 0;
            block_index  <= 0;
            plaintext_in <= block_array[0];
        end
        else if (insertion_just_started) begin
            // Block 0 was already held (and effectively consumed)
            // during the hold period, so jump straight to block 1
            // instead of replaying block 0 for a full period.
            clk_counter  <= 0;
            block_index  <= 1;
            plaintext_in <= block_array[1];
        end
        else begin
            if (block_index < NUM_BLOCKS) begin
                clk_counter <= clk_counter + 1;

                if (clk_counter == CLOCKS_PER_NEW_BLOCK - 1) begin
                    clk_counter <= 0;

                    if (block_index + 1 < NUM_BLOCKS) begin
                        plaintext_in <= block_array[block_index + 1];
                    end

                    block_index <= block_index + 1;
                end
            end
            // once block_index == NUM_BLOCKS, everything just holds steady
        end
    end

    //------------------------------------------------------------
    // Stimulus
    //------------------------------------------------------------
    initial begin

        // Initialize
        rst = 0;          // Active-low reset asserted
        sof = 0;

        aes_key = 128'h000102030405060708090A0B0C0D0E0F;

        //--------------------------------------------------------
        // Hold reset
        //--------------------------------------------------------
        repeat (10) @(posedge clk);

        rst = 1;          // Release reset

        repeat (4) @(posedge clk);

        //--------------------------------------------------------
        // Start streaming: sof once, new plaintext block loads
        // automatically every CLOCKS_PER_NEW_BLOCK clocks via the
        // always block above, but only after INSERTION_START_DELAY
        // clocks have elapsed since reset release, stopping after
        // NUM_BLOCKS blocks.
        //--------------------------------------------------------
        sof = 1;
        @(posedge clk);
        sof = 0;

        //--------------------------------------------------------
        // Wait long enough for the insertion delay to elapse, all
        // NUM_BLOCKS to load, AND drain fully through the TX/RX
        // chain.
        //--------------------------------------------------------
        repeat (12000) @(posedge clk);

        $display("----------------------------------------");
        $display("Simulation Finished");
        $display("----------------------------------------");
        $display("Blocks sent : %0d", block_index);

        $finish;
    end

    //------------------------------------------------------------
    // Simple monitor: just print decrypted output as it comes,
    // no automatic pass/fail check (check manually in waveform)
    //------------------------------------------------------------
    always @(posedge clk) begin
        if (aes_dec_valid) begin
            $display("[%0t ns] AES Decrypted Data = %032h", $time, aes_dec_out);
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