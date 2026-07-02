`timescale 1ns/1ps

module tb_Top_module;

reg clk;
reg rst;
reg valid_in;

reg signed [15:0] I;
reg signed [15:0] Q;

wire [3:0] symbol;
wire [15:0] angle_wave;
wire valid_out;

//==========================================================
// DUT
//==========================================================

Top_module DUT
(
    .clk(clk),
    .rst(rst),
    .valid_in(valid_in),
    .I(I),
    .Q(Q),
    .symbol(symbol),
    .angle_wave(angle_wave),
    .valid_out(valid_out)
);

//==========================================================
// Clock
//==========================================================

initial
    clk = 0;

always #5 clk = ~clk;

//==========================================================
// Memory
//==========================================================

reg signed [15:0] I_mem [0:47];
reg signed [15:0] Q_mem [0:47];

integer infile;
integer i;

//==========================================================
// Read IQ vectors
//==========================================================

initial
begin

    infile = $fopen("iq_vectors.txt","r");

    if(infile == 0)
    begin
        $display("Cannot open iq_vectors.txt");
        $finish;
    end

    for(i=0;i<48;i=i+1)
        $fscanf(infile,"%d %d\n",I_mem[i],Q_mem[i]);

    $fclose(infile);

end

//==========================================================
// Stimulus
//==========================================================

initial
begin

    rst = 1;
    valid_in = 0;
    I = 0;
    Q = 0;

    repeat(4) @(posedge clk);

    rst = 0;

    for(i=0;i<48;i=i+1)
    begin

        @(posedge clk);

        I <= I_mem[i];
        Q <= Q_mem[i];

        // Assert valid_in only once
        if(i == 2)
            valid_in <= 1'b1;
        else
            valid_in <= 1'b0;

    end

    repeat(20) @(posedge clk);

    $finish;

end

//==========================================================
// Monitor
//==========================================================

always @(posedge clk)
begin
    $display("Time=%0t  valid_in=%b  valid_out=%b  I=%6d  Q=%6d  Angle=%5d  Symbol=%d",
              $time,
              valid_in,
              valid_out,
              I,
              Q,
              angle_wave,
              symbol);
end

endmodule