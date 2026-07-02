`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// Top-level RS(208,192) decoder.
// Input:  one received 8-bit symbol per clock while enable=1.
// Output: 192 corrected data symbols, one per clock while out_valid=1.
// reset is active-low.
// -----------------------------------------------------------------------------
module Top_decoder (
    input        clock,
    input        reset,
    input        enable,
    input  [7:0] received_symbol,
    output       out_valid,
    output [7:0] Cx
);

wire [127:0] syndromes;
wire         syndromes_ready;

wire [71:0] lambda;
wire [5:0]  num_errors;
wire        bm_done;

wire        error_found;
wire [7:0]  Xi;
wire [7:0]  alpha_power;
wire [5:0]  chien_error_count;
wire        chien_done;
wire        decode_fail_unused;

Syndrome U1 (
    .clk              (clock),
    .reset            (reset),
    .enable           (enable),
    .received_symbol  (received_symbol),
    .syndromes        (syndromes),
    .syndromes_ready  (syndromes_ready)
);

B_M_Algorithm U2 (
    .clk       (clock),
    .reset     (reset),
    .start     (syndromes_ready),
    .syndromes (syndromes),
    .lambda    (lambda),
    .L         (num_errors),
    .done      (bm_done)
);

Chien_Search U4 (
    .clk          (clock),
    .reset        (reset),
    .start        (bm_done),
    .lambda       (lambda),
    .L            (num_errors),
    .error_found  (error_found),
    .xi           (Xi),
    .alpha_power  (alpha_power),
    .error_count  (chien_error_count),
    .done         (chien_done)
);

Forney_Algorithm U5 (
    .clk             (clock),
    .reset           (reset),
    .rec_en          (enable),
    .Rx              (received_symbol),
    .chien_start     (bm_done),
    .error_found_en  (error_found),
    .Xi              (Xi),
    .alpha_power     (alpha_power),
    .chien_done      (chien_done),
    .num_errors      (num_errors),
    .syndromes       (syndromes),
    .lambda          (lambda),
    .out_valid       (out_valid),
    .Cx              (Cx),
    .decode_fail     (decode_fail_unused)
);

endmodule