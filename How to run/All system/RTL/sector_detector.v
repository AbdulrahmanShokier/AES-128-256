module sector_detector
(
    input  wire [15:0] angle,
    output reg  [3:0] index
);

always @(*)
begin

    if(angle < 16'd2048)
        index = 4'd0;

    else if(angle < 16'd6144)
        index = 4'd1;

    else if(angle < 16'd10240)
        index = 4'd2;

    else if(angle < 16'd14336)
        index = 4'd3;

    else if(angle < 16'd18432)
        index = 4'd4;

    else if(angle < 16'd22528)
        index = 4'd5;

    else if(angle < 16'd26624)
        index = 4'd6;

    else if(angle < 16'd30720)
        index = 4'd7;

    else if(angle < 16'd34816)
        index = 4'd8;

    else if(angle < 16'd38912)
        index = 4'd9;

    else if(angle < 16'd43008)
        index = 4'd10;

    else if(angle < 16'd47104)
        index = 4'd11;

    else if(angle < 16'd51200)
        index = 4'd12;

    else if(angle < 16'd55296)
        index = 4'd13;

    else if(angle < 16'd59392)
        index = 4'd14;

    else if(angle < 16'd63488)
        index = 4'd15;

    else
        index = 4'd0;

end

endmodule