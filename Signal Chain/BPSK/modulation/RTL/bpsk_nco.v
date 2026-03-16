module bpsk_nco #(
    parameter COS_WIDTH = 16
)
(
    input                               rst,
    input                               clk_sample,
    output reg signed [COS_WIDTH-1 : 0] cos_value

);

reg [COS_WIDTH-1 : 0] cosine_lut [0:255];

reg [7 : 0] phase_accumulator; // 8 bits for address in cos_lut 

reg [1 : 0] quarter_detector;  // 2 bits for quarter detection

initial begin
    cosine_lut[0]   = 16'd16384;  cosine_lut[1]   = 16'd16383;  cosine_lut[2]   = 16'd16381;
    cosine_lut[3]   = 16'd16379;  cosine_lut[4]   = 16'd16376;  cosine_lut[5]   = 16'd16373;
    cosine_lut[6]   = 16'd16369;  cosine_lut[7]   = 16'd16364;  cosine_lut[8]   = 16'd16359;
    cosine_lut[9]   = 16'd16353;  cosine_lut[10]  = 16'd16347;  cosine_lut[11]  = 16'd16340;
    cosine_lut[12]  = 16'd16332;  cosine_lut[13]  = 16'd16324;  cosine_lut[14]  = 16'd16315;
    cosine_lut[15]  = 16'd16305;  cosine_lut[16]  = 16'd16295;  cosine_lut[17]  = 16'd16284;
    cosine_lut[18]  = 16'd16273;  cosine_lut[19]  = 16'd16261;  cosine_lut[20]  = 16'd16248;
    cosine_lut[21]  = 16'd16235;  cosine_lut[22]  = 16'd16221;  cosine_lut[23]  = 16'd16207;
    cosine_lut[24]  = 16'd16192;  cosine_lut[25]  = 16'd16176;  cosine_lut[26]  = 16'd16160;
    cosine_lut[27]  = 16'd16143;  cosine_lut[28]  = 16'd16125;  cosine_lut[29]  = 16'd16107;
    cosine_lut[30]  = 16'd16088;  cosine_lut[31]  = 16'd16069;  cosine_lut[32]  = 16'd16049;
    cosine_lut[33]  = 16'd16029;  cosine_lut[34]  = 16'd16008;  cosine_lut[35]  = 16'd15986;
    cosine_lut[36]  = 16'd15964;  cosine_lut[37]  = 16'd15941;  cosine_lut[38]  = 16'd15917;
    cosine_lut[39]  = 16'd15893;  cosine_lut[40]  = 16'd15868;  cosine_lut[41]  = 16'd15843;
    cosine_lut[42]  = 16'd15817;  cosine_lut[43]  = 16'd15791;  cosine_lut[44]  = 16'd15763;
    cosine_lut[45]  = 16'd15736;  cosine_lut[46]  = 16'd15707;  cosine_lut[47]  = 16'd15679;
    cosine_lut[48]  = 16'd15649;  cosine_lut[49]  = 16'd15619;  cosine_lut[50]  = 16'd15588;
    cosine_lut[51]  = 16'd15557;  cosine_lut[52]  = 16'd15525;  cosine_lut[53]  = 16'd15493;
    cosine_lut[54]  = 16'd15460;  cosine_lut[55]  = 16'd15426;  cosine_lut[56]  = 16'd15392;
    cosine_lut[57]  = 16'd15357;  cosine_lut[58]  = 16'd15322;  cosine_lut[59]  = 16'd15286;
    cosine_lut[60]  = 16'd15250;  cosine_lut[61]  = 16'd15213;  cosine_lut[62]  = 16'd15175;
    cosine_lut[63]  = 16'd15137;  cosine_lut[64]  = 16'd15098;  cosine_lut[65]  = 16'd15059;
    cosine_lut[66]  = 16'd15019;  cosine_lut[67]  = 16'd14978;  cosine_lut[68]  = 16'd14937;
    cosine_lut[69]  = 16'd14896;  cosine_lut[70]  = 16'd14854;  cosine_lut[71]  = 16'd14811;
    cosine_lut[72]  = 16'd14768;  cosine_lut[73]  = 16'd14724;  cosine_lut[74]  = 16'd14680;
    cosine_lut[75]  = 16'd14635;  cosine_lut[76]  = 16'd14589;  cosine_lut[77]  = 16'd14543;
    cosine_lut[78]  = 16'd14497;  cosine_lut[79]  = 16'd14449;  cosine_lut[80]  = 16'd14402;
    cosine_lut[81]  = 16'd14354;  cosine_lut[82]  = 16'd14305;  cosine_lut[83]  = 16'd14256;
    cosine_lut[84]  = 16'd14206;  cosine_lut[85]  = 16'd14155;  cosine_lut[86]  = 16'd14104;
    cosine_lut[87]  = 16'd14053;  cosine_lut[88]  = 16'd14001;  cosine_lut[89]  = 16'd13949;
    cosine_lut[90]  = 16'd13896;  cosine_lut[91]  = 16'd13842;  cosine_lut[92]  = 16'd13788;
    cosine_lut[93]  = 16'd13733;  cosine_lut[94]  = 16'd13678;  cosine_lut[95]  = 16'd13623;
    cosine_lut[96]  = 16'd13567;  cosine_lut[97]  = 16'd13510;  cosine_lut[98]  = 16'd13453;
    cosine_lut[99]  = 16'd13395;  cosine_lut[100] = 16'd13337;  cosine_lut[101] = 16'd13279;
    cosine_lut[102] = 16'd13219;  cosine_lut[103] = 16'd13160;  cosine_lut[104] = 16'd13100;
    cosine_lut[105] = 16'd13039;  cosine_lut[106] = 16'd12978;  cosine_lut[107] = 16'd12916;
    cosine_lut[108] = 16'd12854;  cosine_lut[109] = 16'd12792;  cosine_lut[110] = 16'd12729;
    cosine_lut[111] = 16'd12665;  cosine_lut[112] = 16'd12601;  cosine_lut[113] = 16'd12537;
    cosine_lut[114] = 16'd12472;  cosine_lut[115] = 16'd12406;  cosine_lut[116] = 16'd12340;
    cosine_lut[117] = 16'd12274;  cosine_lut[118] = 16'd12207;  cosine_lut[119] = 16'd12140;
    cosine_lut[120] = 16'd12072;  cosine_lut[121] = 16'd12004;  cosine_lut[122] = 16'd11935;
    cosine_lut[123] = 16'd11866;  cosine_lut[124] = 16'd11797;  cosine_lut[125] = 16'd11727;
    cosine_lut[126] = 16'd11656;  cosine_lut[127] = 16'd11585;  cosine_lut[128] = 16'd11514;
    cosine_lut[129] = 16'd11442;  cosine_lut[130] = 16'd11370;  cosine_lut[131] = 16'd11297;
    cosine_lut[132] = 16'd11224;  cosine_lut[133] = 16'd11151;  cosine_lut[134] = 16'd11077;
    cosine_lut[135] = 16'd11003;  cosine_lut[136] = 16'd10928;  cosine_lut[137] = 16'd10853;
    cosine_lut[138] = 16'd10778;  cosine_lut[139] = 16'd10702;  cosine_lut[140] = 16'd10625;
    cosine_lut[141] = 16'd10549;  cosine_lut[142] = 16'd10471;  cosine_lut[143] = 16'd10394;
    cosine_lut[144] = 16'd10316;  cosine_lut[145] = 16'd10238;  cosine_lut[146] = 16'd10159;
    cosine_lut[147] = 16'd10080;  cosine_lut[148] = 16'd10001;  cosine_lut[149] = 16'd9921;
    cosine_lut[150] = 16'd9841;   cosine_lut[151] = 16'd9760;   cosine_lut[152] = 16'd9679;
    cosine_lut[153] = 16'd9598;   cosine_lut[154] = 16'd9516;   cosine_lut[155] = 16'd9434;
    cosine_lut[156] = 16'd9352;   cosine_lut[157] = 16'd9269;   cosine_lut[158] = 16'd9186;
    cosine_lut[159] = 16'd9102;   cosine_lut[160] = 16'd9019;   cosine_lut[161] = 16'd8935;
    cosine_lut[162] = 16'd8850;   cosine_lut[163] = 16'd8765;   cosine_lut[164] = 16'd8680;
    cosine_lut[165] = 16'd8595;   cosine_lut[166] = 16'd8509;   cosine_lut[167] = 16'd8423;
    cosine_lut[168] = 16'd8337;   cosine_lut[169] = 16'd8250;   cosine_lut[170] = 16'd8163;
    cosine_lut[171] = 16'd8076;   cosine_lut[172] = 16'd7988;   cosine_lut[173] = 16'd7900;
    cosine_lut[174] = 16'd7812;   cosine_lut[175] = 16'd7723;   cosine_lut[176] = 16'd7635;
    cosine_lut[177] = 16'd7545;   cosine_lut[178] = 16'd7456;   cosine_lut[179] = 16'd7366;
    cosine_lut[180] = 16'd7276;   cosine_lut[181] = 16'd7186;   cosine_lut[182] = 16'd7096;
    cosine_lut[183] = 16'd7005;   cosine_lut[184] = 16'd6914;   cosine_lut[185] = 16'd6823;
    cosine_lut[186] = 16'd6731;   cosine_lut[187] = 16'd6639;   cosine_lut[188] = 16'd6547;
    cosine_lut[189] = 16'd6455;   cosine_lut[190] = 16'd6363;   cosine_lut[191] = 16'd6270;
    cosine_lut[192] = 16'd6177;   cosine_lut[193] = 16'd6084;   cosine_lut[194] = 16'd5990;
    cosine_lut[195] = 16'd5897;   cosine_lut[196] = 16'd5803;   cosine_lut[197] = 16'd5708;
    cosine_lut[198] = 16'd5614;   cosine_lut[199] = 16'd5520;   cosine_lut[200] = 16'd5425;
    cosine_lut[201] = 16'd5330;   cosine_lut[202] = 16'd5235;   cosine_lut[203] = 16'd5139;
    cosine_lut[204] = 16'd5044;   cosine_lut[205] = 16'd4948;   cosine_lut[206] = 16'd4852;
    cosine_lut[207] = 16'd4756;   cosine_lut[208] = 16'd4660;   cosine_lut[209] = 16'd4563;
    cosine_lut[210] = 16'd4467;   cosine_lut[211] = 16'd4370;   cosine_lut[212] = 16'd4273;
    cosine_lut[213] = 16'd4176;   cosine_lut[214] = 16'd4078;   cosine_lut[215] = 16'd3981;
    cosine_lut[216] = 16'd3883;   cosine_lut[217] = 16'd3786;   cosine_lut[218] = 16'd3688;
    cosine_lut[219] = 16'd3590;   cosine_lut[220] = 16'd3492;   cosine_lut[221] = 16'd3393;
    cosine_lut[222] = 16'd3295;   cosine_lut[223] = 16'd3196;   cosine_lut[224] = 16'd3098;
    cosine_lut[225] = 16'd2999;   cosine_lut[226] = 16'd2900;   cosine_lut[227] = 16'd2801;
    cosine_lut[228] = 16'd2702;   cosine_lut[229] = 16'd2603;   cosine_lut[230] = 16'd2503;
    cosine_lut[231] = 16'd2404;   cosine_lut[232] = 16'd2305;   cosine_lut[233] = 16'd2205;
    cosine_lut[234] = 16'd2105;   cosine_lut[235] = 16'd2006;   cosine_lut[236] = 16'd1906;
    cosine_lut[237] = 16'd1806;   cosine_lut[238] = 16'd1706;   cosine_lut[239] = 16'd1606;
    cosine_lut[240] = 16'd1506;   cosine_lut[241] = 16'd1406;   cosine_lut[242] = 16'd1306;
    cosine_lut[243] = 16'd1205;   cosine_lut[244] = 16'd1105;   cosine_lut[245] = 16'd1005;
    cosine_lut[246] = 16'd904;    cosine_lut[247] = 16'd804;    cosine_lut[248] = 16'd704;
    cosine_lut[249] = 16'd603;    cosine_lut[250] = 16'd503;    cosine_lut[251] = 16'd402;
    cosine_lut[252] = 16'd302;    cosine_lut[253] = 16'd201;    cosine_lut[254] = 16'd101;
    cosine_lut[255] = 16'd0;
end


///////////////////////// output logic ////////////////////////////////
always@(posedge clk_sample)
begin
    if(!rst)
        cos_value <= 16'b0;
    else if ((quarter_detector == 2'b00) || (quarter_detector == 2'b11))
        cos_value <= cosine_lut[phase_accumulator];
    else
        cos_value <= -cosine_lut[phase_accumulator];
end


////////////////////// phase accumulator logic/////////////////////
always@(posedge clk_sample)
begin
    if(!rst)
    begin
        phase_accumulator <= 8'b0;
        quarter_detector  <= 2'b0;
    end
    else 
    begin
        if (quarter_detector == 2'b00 || quarter_detector == 2'b10) 
        begin
        phase_accumulator <= phase_accumulator + 1;
            if (phase_accumulator == 8'd254)
                quarter_detector <= quarter_detector + 1;
        end
        else if (quarter_detector == 2'b01 || quarter_detector == 2'b11 )
        begin
        phase_accumulator <= phase_accumulator - 1;
            if (phase_accumulator == 8'd1)
                quarter_detector <= quarter_detector + 1;
        end
    end
end

endmodule


// cuurently the carrier frequency is the clk_sample divided by 1024 (because we have 256 value for one quarter in the cos wave )
// for anther carrier frequency we have to use another clock or change the phase accumator increament 
// it can be changed but we will stick to the current frequnecy till checking if its working or no