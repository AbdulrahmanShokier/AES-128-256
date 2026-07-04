`timescale 1ns/1ps

module tb_DVB_tx_top;

    // ------------------------------------------------------------------
    // PREAMBLE_WIDTH/CONTROL_WIDTH set to full real size here.
    // aes_word_count/crc_width are now exposed as DVB_tx_top parameters
    // (previously they were NOT, and Data/Crc always ran at the full
    // 350/32 length no matter what - that gap is fixed) and are scaled
    // down here so the Data/Crc phases finish in a reasonable simulation
    // time instead of running the full 350-codeword frame.
    //
    // NOTE on Data phase timing: aes_word_count is NOT "bits per frame" -
    // it is the number of full RS codewords the Data state waits through
    // before moving to Crc. Each AES word is 128 bits and takes exactly
    // ONE period (32 symbol_ticks) to encrypt/load (periods 1-12). It is
    // the RS(208,192) codeword - built from those 12 AES words plus a
    // 13th, parity-only period - that spans all 13 periods (13*32 = 416
    // symbol_ticks). Despite its name, aes_word_counter (inside
    // DVB_all_tx_fsm) actually increments once per completed CODEWORD
    // (verified: it fires 14 ticks after cyc==31 of period 13), not once
    // per individual AES word - so aes_word_count below really means
    // "codewords per frame." The previous repeat() used
    // 350 * RS_N * 8 symbol_ticks, which doesn't match how the FSM
    // actually measures Data phase length (via aes_word_counter, gated by
    // the period/cyc structure) - removed.
    // ------------------------------------------------------------------
    localparam BLOCK_LENGTH = 128;
    localparam P_PRE        = 255; // PREAMBLE_WIDTH
    localparam P_CTRL       = 256; // CONTROL_WIDTH
    localparam PCW          = 8;   // PREAMBLE_COUNTER_WIDTH (must hold P_PRE)
    localparam CCW          = 8;   // CONTROL_COUNTER_WIDTH  (must hold P_CTRL)
    localparam RS_N         = 208;

    localparam AES_WORD_COUNT = 1; // scaled down from 350 for fast sim
    localparam CRC_WIDTH      = 32; // scaled down from 32 for fast sim

    // One RS(208,192) codeword spans 13 periods * 32 symbol_ticks = 416
    // symbol_ticks (12 periods load/encrypt one 128-bit AES word each,
    // the 13th period is parity-only - no new AES word). This is what
    // TICKS_PER_CODEWORD measures below, NOT a single AES word.
    localparam TICKS_PER_CODEWORD = 13 * 32;

    reg                     clk_sample;
    reg                     rst;
    reg                     sof;
    reg  [BLOCK_LENGTH-1:0] plaintext_in;
    reg  [BLOCK_LENGTH-1:0] aes_key;

    wire signed [15:0]      preamble_bb;
    wire signed [15:0]      I_out;
    wire signed [15:0]      Q_out;
    wire [3:0]              period_count_o;
    wire [2:0]              rs_current_state_o;

    DVB_tx_top #(
        .BLOCK_LENGTH(BLOCK_LENGTH),
        .PREAMBLE_WIDTH(P_PRE),
        .CONTROL_WIDTH(P_CTRL),
        .PREAMBLE_COUNTER_WIDTH(PCW),
        .CONTROL_COUNTER_WIDTH(CCW),
        .aes_word_count(AES_WORD_COUNT),
        .crc_width(CRC_WIDTH)
    ) dut (
        .clk_sample(clk_sample),
        .rst(rst),
        .sof(sof),
        .plaintext_in(plaintext_in),
        .aes_key(aes_key),
        .preamble_bb(preamble_bb),
        .I_out(I_out),
        .Q_out(Q_out),
        .period_count_o(period_count_o),
        .rs_current_state_o(rs_current_state_o)
    );

    reg [1:0] symbol_cnt;

    always @(posedge clk_sample) begin
        if (!rst)
            symbol_cnt <= 2'd0;
        else
            symbol_cnt <= symbol_cnt + 2'b1;
    end

    wire symbol_tick = (symbol_cnt == 2'd0);



    reg [16:0] sample_counter;

    always @(posedge clk_sample) begin
        if (!rst)
            sample_counter <= 17'd0;
        else
            sample_counter <= sample_counter + 17'b1;
    end


    initial clk_sample = 0;
    always #5 clk_sample = ~clk_sample;

    // ------------------------------------------------------------------
    // CSV logging (Excel-readable) for preamble_bb, I_out, Q_out.
    // One row per symbol_tick, which is the actual sample rate of these
    // signals (they only update once every 4 clk_sample cycles).
    // sample_idx is shared across both files so row N in preamble_bb.csv
    // and row N in iq_out.csv refer to the exact same sample/time.
    // ------------------------------------------------------------------
    integer preamble_csv;
    integer iq_csv;
    integer sample_idx;

    initial begin
        sample_idx   = 0;
        preamble_csv = $fopen("preamble_bb.csv", "w");
        iq_csv       = $fopen("iq_out.csv", "w");
        $fwrite(preamble_csv, "sample_idx,time_ns,preamble_bb\n");
        $fwrite(iq_csv,       "sample_idx,time_ns,I_out,Q_out\n");
    end

    always @(posedge clk_sample) begin
        if (rst) begin
            $fwrite(preamble_csv, "%0d,%0t,%0d\n",
                    sample_idx, $time, $signed(preamble_bb));
            $fwrite(iq_csv, "%0d,%0t,%0d,%0d\n",
                    sample_idx, $time, $signed(I_out), $signed(Q_out));
            sample_idx <= sample_idx + 1;
        end
    end

    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_DVB_tx_top);

        rst          = 0;
        sof          = 0;
        plaintext_in = 128'h00112233445566778899AABBCCDDEEFF;
        aes_key      = 128'h000102030405060708090A0B0C0D0E0F;

        repeat (2) @(posedge clk_sample);
        rst = 1;

        repeat (2) @(posedge clk_sample);
        sof = 1;
        repeat (4) @(posedge clk_sample); // hold sof long enough to catch a symbol_tick
        sof = 0;

        // Preamble + Control + Data (AES_WORD_COUNT codewords, each
        // TICKS_PER_CODEWORD symbol_ticks long) + Crc (CRC_WIDTH ticks) +
        // margin. Each symbol_tick = 4 clk_sample cycles.
        repeat (4 * (P_PRE + P_CTRL
                      + AES_WORD_COUNT * TICKS_PER_CODEWORD
                      + CRC_WIDTH + 20)) @(posedge clk_sample);

        $display("TB done at %0t", $time);
        $fclose(preamble_csv);
        $fclose(iq_csv);
        $finish;
    end

    // Phase-enable transition trace - just enough to confirm the FSM
    // walks through all four phases in order.
    reg preamble_en_d, control_en_d, data_en_d, crc_en_d;

    always @(posedge clk_sample) begin
        if (symbol_tick) begin
            if (dut.preamble_en !== preamble_en_d)
                $display("[%0t] preamble_en -> %b", $time, dut.preamble_en);
            if (dut.control_en !== control_en_d)
                $display("[%0t] control_en  -> %b", $time, dut.control_en);
            if (dut.data_en !== data_en_d)
                $display("[%0t] data_en     -> %b", $time, dut.data_en);
            if (dut.crc_en !== crc_en_d)
                $display("[%0t] crc_en      -> %b", $time, dut.crc_en);

            preamble_en_d <= dut.preamble_en;
            control_en_d  <= dut.control_en;
            data_en_d     <= dut.data_en;
            crc_en_d      <= dut.crc_en;
        end
    end

endmodule
