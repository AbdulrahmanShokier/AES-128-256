`timescale 1ns / 1ps
module rs_decoder_top #(
    parameter N  = 255,   
    parameter K  = 223,   
    parameter T  = 16,    
    parameter T2 = 32     
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] rx_data,
    input  wire       rx_valid,
    output reg  [7:0] tx_data,
    output reg        tx_valid,
    output reg        decode_fail,
    output reg        frame_done
);

    localparam [2:0] S_IDLE = 3'd0, S_RECEIVE = 3'd1, S_BM = 3'd2, S_CHIEN = 3'd3, S_OUTPUT = 3'd4;
    reg [2:0] state, next_state;

    reg          syn_clr;
    wire [255:0] syn_out;       
    wire         syn_done;

    reg          bm_start;
    wire [127:0] lambda;
    wire [4:0]   err_count;
    wire         bm_done;

    reg          chien_start;
    wire [7:0]   chien_err_pos;
    wire [7:0]   chien_err_val;
    wire         chien_err_valid;
    wire         chien_decode_fail;
    wire         chien_done;

    reg          pmem_wr_b_en;
    reg  [7:0]   pmem_wr_b_addr;
    reg  [7:0]   pmem_wr_b_data;
    reg          pmem_rd_en;
    reg  [7:0]   pmem_rd_addr;
    wire [7:0]   pmem_rd_data;

    reg [7:0] rx_cnt;
    reg [7:0] tx_cnt;

    syndrome_calc #(.N(N), .T2(T2)) u_syn (
        .clk        (clk),
        .rst_n      (rst_n),
        .clr        (syn_clr),
        .data_in    (rx_data),
        .data_valid (rx_valid && (state == S_IDLE || state == S_RECEIVE)),
        .syn_out    (syn_out),
        .done       (syn_done)
    );

    berlekamp_massey #(.T2(T2)) u_bm (
        .clk       (clk), .rst_n     (rst_n), .start     (bm_start),
        .syn_in    (syn_out), .lambda    (lambda), .err_count (err_count), .done      (bm_done)
    );

    chien_search #(.N(N), .T(T), .T2(T2)) u_chien (
        .clk         (clk), .rst_n       (rst_n), .start       (chien_start),
        .syn_in      (syn_out), .lambda      (lambda), .err_count   (err_count),
        .err_pos     (chien_err_pos), .err_val     (chien_err_val),
        .err_valid   (chien_err_valid), .decode_fail (chien_decode_fail), .done        (chien_done)
    );

    pipeline_mem #(.N(N)) u_pmem (
        .clk       (clk),
        // Driven combinationally here to perfectly align Byte 0 with Address 0
        .wr_a_en   (rx_valid && (state == S_IDLE || state == S_RECEIVE)),
        .wr_a_addr (rx_cnt),
        .wr_a_data (rx_data),
        .wr_b_en   (pmem_wr_b_en), .wr_b_addr (pmem_wr_b_addr), .wr_b_data (pmem_wr_b_data),
        .rd_b_en   (pmem_rd_en), .rd_b_addr (pmem_rd_addr), .rd_b_data (pmem_rd_data)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= S_IDLE;
        else        state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE:    if (rx_valid)     next_state = S_RECEIVE;
            S_RECEIVE: if (syn_done)     next_state = S_BM;
            S_BM:      if (bm_done)      next_state = S_CHIEN;
            S_CHIEN:   if (chien_done)   next_state = S_OUTPUT;
            S_OUTPUT:  if (tx_cnt == N)  next_state = S_IDLE;
            default:                     next_state = S_IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_cnt <= 8'd0; tx_cnt <= 8'd0; bm_start <= 1'b0; chien_start <= 1'b0;
            syn_clr <= 1'b0; pmem_wr_b_en <= 1'b0; pmem_wr_b_addr <= 8'd0; pmem_wr_b_data <= 8'd0;
            pmem_rd_en <= 1'b0; pmem_rd_addr <= 8'd0; tx_data <= 8'd0; tx_valid <= 1'b0;
            decode_fail <= 1'b0; frame_done <= 1'b0;
        end else begin
            bm_start <= 1'b0; chien_start <= 1'b0; syn_clr <= 1'b0; pmem_wr_b_en <= 1'b0;
            pmem_rd_en <= 1'b0; tx_valid <= 1'b0; frame_done <= 1'b0;

            case (state)
                S_IDLE: begin
                    rx_cnt <= 8'd0; tx_cnt <= 8'd0;
                    if (rx_valid) begin
                        decode_fail <= 1'b0;
                        rx_cnt      <= 8'd1;
                    end
                end
                S_RECEIVE: begin
                    if (rx_valid) rx_cnt <= rx_cnt + 8'd1;
                end
                S_BM: ; 
                S_CHIEN: begin
                    if (chien_done) decode_fail <= chien_decode_fail;
                    if (chien_err_valid) begin
                        pmem_wr_b_en   <= 1'b1;
                        pmem_wr_b_addr <= chien_err_pos;
                        pmem_wr_b_data <= chien_err_val;
                    end
                end
                S_OUTPUT: begin
                    if (tx_cnt < N) begin
                        pmem_rd_en   <= 1'b1;
                        pmem_rd_addr <= tx_cnt;
                        tx_cnt       <= tx_cnt + 8'd1;
                    end
                    if (tx_cnt > 8'd0) begin
                        tx_data  <= pmem_rd_data;
                        tx_valid <= 1'b1;
                    end
                    if (tx_cnt == N) begin
                        frame_done <= 1'b1;
                        syn_clr    <= 1'b1;
                    end
                end
                default: ;
            endcase

            if (state == S_RECEIVE && next_state == S_BM) bm_start <= 1'b1;
            if (state == S_BM && next_state == S_CHIEN) chien_start <= 1'b1;
        end
    end
endmodule