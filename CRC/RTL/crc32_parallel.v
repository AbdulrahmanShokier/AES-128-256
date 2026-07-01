// =============================================================================
// crc32_parallel.v
//
// High-throughput parallel CRC-32 generator
// Polynomial : 0x04C11DB7 (DVB / Ethernet CRC polynomial)
//
// This implementation computes CRC for DATA_W bits in ONE clock cycle
// using a precomputed transformation matrix.
//
// Main idea:
// Instead of shifting the CRC serially bit-by-bit,
// we algebraically unroll the CRC operation into parallel XOR equations.
//
// Architecture:
//   Current CRC + Input Data
//            |
//      XOR transformation matrix
//            |
//        Next CRC value
//
// Verilog-2001 compatible — no SystemVerilog syntax used.
// Tested with: Modelsim, Questa, Vivado xvlog (Verilog mode)
// =============================================================================

module crc32_dvb #(
    parameter DATA_W = 32   // Number of bits processed per clock
)(
    input  wire              clk,
    input  wire              rst_n,

    // Start Of Frame:
    // When asserted, CRC starts from CRC_INIT instead of previous state
    input  wire              sof,

    // Input data valid
    input  wire              valid,

    // Parallel input data (MSB first, as required by DVB)
    input  wire [DATA_W-1:0] data_in,

    // End Of Frame:
    // Causes crc_out and crc_valid to update on the next cycle
    input  wire              eof,

    // Final CRC output (registered)
    output reg  [31:0]       crc_out,

    // Pulses high for one cycle when crc_out is valid
    output reg               crc_valid
);

    // ------------------------------------------------------------------
    // CRC polynomial
    //
    // x^32 + x^26 + x^23 + x^22 + x^16 + x^12 + x^11 + x^10 +
    // x^8  + x^7  + x^5  + x^4  + x^2  + x^1  + 1
    //
    // Standard CRC-32 polynomial used in DVB-S2, DVB-T2, Ethernet
    // ------------------------------------------------------------------
    localparam [31:0] POLY     = 32'h04C11DB7;

    // Initial CRC seed value (all ones, mandated by DVB)
    localparam [31:0] CRC_INIT = 32'hFFFFFFFF;

    // Total input vector width: DATA_W data bits + 32 CRC state bits
    localparam integer TOTAL   = 32 + DATA_W;


    // ------------------------------------------------------------------
    // Matrix generation function (pure Verilog-2001)
    //
    // Precomputes the XOR dependency matrix that transforms:
    //
    //    { data_in , current_crc }   →   next_crc
    //
    // Each of the 32 output CRC bits is expressed as an XOR of a
    // subset of the TOTAL input bits. This subset is encoded as a
    // TOTAL-wide bitmask (one row of the matrix).
    //
    // The function simulates DATA_W serial LFSR steps symbolically:
    // instead of propagating real bit values it propagates dependency
    // masks, so after DATA_W iterations each row holds the complete
    // XOR equation for that output bit.
    //
    // Notes on Verilog-2001 compatibility:
    //   - 'automatic' keyword removed (not needed for a localparam call)
    //   - TOTAL'(1) cast replaced with the expression below:
    //       ({(TOTAL-1){1'b0}}, 1'b1) << position
    //     which is plain Verilog-2001 concatenation + shift
    //   - dummy input added because Verilog-2001 requires at least
    //     one input port on every function
    // ------------------------------------------------------------------
    function [32*TOTAL-1:0] gen_matrix;

        input dummy;    // required by Verilog-2001 — value is ignored

        integer i, b;

        // One row per CRC output bit.
        // Row i is a TOTAL-wide mask: bit j set means input bit j
        // contributes to output CRC bit i.
        reg [TOTAL-1:0] row [0:31];

        // Feedback mask for one symbolic LFSR step
        reg [TOTAL-1:0] st;

        begin

            // ----------------------------------------------------------
            // Initialise as identity for the CRC state bits.
            //
            // row[i] = unit vector with only bit i set.
            // Meaning: "output CRC bit i currently depends only on
            //           input CRC bit i."
            // Data bits have no influence yet.
            //
            // Verilog-2001 shift of a TOTAL-wide constant:
            //   ({(TOTAL-1){1'b0}}, 1'b1) builds a TOTAL-bit 1,
            //   then << i shifts it to position i.
            // ----------------------------------------------------------
            for (i = 0; i < 32; i = i + 1)
                row[i] = ({{(TOTAL-1){1'b0}}, 1'b1} << i);


            // ----------------------------------------------------------
            // Symbolically simulate DATA_W serial LFSR steps.
            //
            // At each step b, the data bit entering the LFSR is
            // data_in[DATA_W-1-b] (MSB first).
            // Its position in the input vector is (32 + DATA_W-1-b).
            //
            // Feedback = crc[31] XOR data_bit
            // In mask space: st = row[31] XOR unit_vector(data_bit_pos)
            //
            // Then apply the standard LFSR shift:
            //   new_crc[i] = old_crc[i-1] XOR (poly[i] * feedback)
            // ----------------------------------------------------------
            for (b = 0; b < DATA_W; b = b + 1) begin

                // Build unit vector for the data bit at this step.
                // Position = 32 + DATA_W - 1 - b
                st = row[31] ^ ({{(TOTAL-1){1'b0}}, 1'b1} << (32 + DATA_W - 1 - b));

                // Shift all rows and apply polynomial taps
                for (i = 31; i >= 1; i = i - 1)
                    row[i] = row[i-1] ^ (POLY[i] ? st : {TOTAL{1'b0}});

                // LSB of CRC only gets feedback, no shift contribution
                row[0] = POLY[0] ? st : {TOTAL{1'b0}};
            end


            // ----------------------------------------------------------
            // Pack all 32 rows into one flat bit-vector.
            // Row i occupies bits [(i+1)*TOTAL-1 : i*TOTAL].
            // ----------------------------------------------------------
            gen_matrix = {(32*TOTAL){1'b0}};

            for (i = 0; i < 32; i = i + 1)
                gen_matrix[i*TOTAL +: TOTAL] = row[i];

        end
    endfunction


    // ------------------------------------------------------------------
    // Precomputed transformation matrix (elaboration-time constant)
    //
    // The synthesiser sees this as a ROM of constants.
    // Each output bit's XOR equation is a fixed mask into vec.
    // ------------------------------------------------------------------
    localparam [32*TOTAL-1:0] MATRIX = gen_matrix(1'b0);


    // ------------------------------------------------------------------
    // CRC state register
    // Holds the running CRC value between clock cycles.
    // ------------------------------------------------------------------
    reg [31:0] state_r;


    // ------------------------------------------------------------------
    // SOF mux
    //
    // Start of frame  → seed with CRC_INIT (0xFFFFFFFF)
    // Mid frame       → continue from state_r
    // ------------------------------------------------------------------
    wire [31:0] crc_seed = sof ? CRC_INIT : state_r;


    // ------------------------------------------------------------------
    // Input vector
    //
    // Concatenate data and CRC seed into one TOTAL-wide vector.
    // data_in occupies the upper DATA_W bits (positions TOTAL-1..32).
    // crc_seed occupies the lower 32 bits (positions 31..0).
    // This matches the bit ordering assumed during matrix generation.
    // ------------------------------------------------------------------
    wire [TOTAL-1:0] vec = {data_in, crc_seed};


    // Next CRC value (combinational output of the XOR network)
    wire [31:0] crc_next;


    // ------------------------------------------------------------------
    // Parallel XOR network
    //
    // For each of the 32 output CRC bits:
    //   1. Extract that bit's dependency mask from MATRIX
    //   2. AND the mask with vec  (select contributing bits)
    //   3. XOR-reduce to one bit  (^ operator)
    //
    // The synthesiser implements each reduction as a balanced XOR tree
    // (~7 levels of XOR2 gates for DATA_W=32, no carry chain).
    // ------------------------------------------------------------------
    genvar gi;

    generate
        for (gi = 0; gi < 32; gi = gi + 1) begin : xr

            // Dependency mask for output CRC bit gi
            wire [TOTAL-1:0] mask = MATRIX[gi*TOTAL +: TOTAL];

            // XOR-reduce: one output bit per row
            assign crc_next[gi] = ^(vec & mask);

        end
    endgenerate


    // ------------------------------------------------------------------
    // Sequential logic
    // ------------------------------------------------------------------
    always @(posedge clk) begin

        // --------------------------------------------------------------
        // Synchronous active-low reset
        // --------------------------------------------------------------
        if (!rst_n) begin
            state_r   <= CRC_INIT;
            crc_out   <= 32'h0;
            crc_valid <= 1'b0;

        end else begin

            // crc_valid is a one-cycle pulse — clear by default
            crc_valid <= 1'b0;

            // ----------------------------------------------------------
            // Accumulate CRC while data is valid.
            // crc_seed already handles the SOF case via the mux above,
            // so no special branch is needed here.
            // ----------------------------------------------------------
            if (valid)
                state_r <= crc_next;

            // ----------------------------------------------------------
            // End of frame:
            //
            // If eof and valid coincide → the last word is in crc_next
            // If eof arrives after valid → use the already-stored state_r
            // ----------------------------------------------------------
            if (eof) begin
                crc_out   <= valid ? crc_next : state_r;
                crc_valid <= 1'b1;
            end

        end
    end

endmodule