module bpsk_nco #(
    parameter COS_WIDTH = 16
)
(
    input                               rst,
    input                               clk_sample,
    output reg signed [COS_WIDTH-1 : 0] cos_value

);

reg signed [COS_WIDTH-1 : 0] cosine_lut [0:255];

reg [7 : 0] phase_accumulator; // 8 bits for address in cos_lut 

reg [1 : 0] quarter_detector;  // 2 bits for quarter detection

initial begin
    cosine_lut[0]   = 16'sd16384;  cosine_lut[1]   = 16'sd16383;  cosine_lut[2]   = 16'sd16381;
    cosine_lut[3]   = 16'sd16379;  cosine_lut[4]   = 16'sd16376;  cosine_lut[5]   = 16'sd16373;
    cosine_lut[6]   = 16'sd16369;  cosine_lut[7]   = 16'sd16364;  cosine_lut[8]   = 16'sd16359;
    cosine_lut[9]   = 16'sd16353;  cosine_lut[10]  = 16'sd16347;  cosine_lut[11]  = 16'sd16340;
    cosine_lut[12]  = 16'sd16332;  cosine_lut[13]  = 16'sd16324;  cosine_lut[14]  = 16'sd16315;
    cosine_lut[15]  = 16'sd16305;  cosine_lut[16]  = 16'sd16295;  cosine_lut[17]  = 16'sd16284;
    cosine_lut[18]  = 16'sd16273;  cosine_lut[19]  = 16'sd16261;  cosine_lut[20]  = 16'sd16248;
    cosine_lut[21]  = 16'sd16235;  cosine_lut[22]  = 16'sd16221;  cosine_lut[23]  = 16'sd16207;
    cosine_lut[24]  = 16'sd16192;  cosine_lut[25]  = 16'sd16176;  cosine_lut[26]  = 16'sd16160;
    cosine_lut[27]  = 16'sd16143;  cosine_lut[28]  = 16'sd16125;  cosine_lut[29]  = 16'sd16107;
    cosine_lut[30]  = 16'sd16088;  cosine_lut[31]  = 16'sd16069;  cosine_lut[32]  = 16'sd16049;
    cosine_lut[33]  = 16'sd16029;  cosine_lut[34]  = 16'sd16008;  cosine_lut[35]  = 16'sd15986;
    cosine_lut[36]  = 16'sd15964;  cosine_lut[37]  = 16'sd15941;  cosine_lut[38]  = 16'sd15917;
    cosine_lut[39]  = 16'sd15893;  cosine_lut[40]  = 16'sd15868;  cosine_lut[41]  = 16'sd15843;
    cosine_lut[42]  = 16'sd15817;  cosine_lut[43]  = 16'sd15791;  cosine_lut[44]  = 16'sd15763;
    cosine_lut[45]  = 16'sd15736;  cosine_lut[46]  = 16'sd15707;  cosine_lut[47]  = 16'sd15679;
    cosine_lut[48]  = 16'sd15649;  cosine_lut[49]  = 16'sd15619;  cosine_lut[50]  = 16'sd15588;
    cosine_lut[51]  = 16'sd15557;  cosine_lut[52]  = 16'sd15525;  cosine_lut[53]  = 16'sd15493;
    cosine_lut[54]  = 16'sd15460;  cosine_lut[55]  = 16'sd15426;  cosine_lut[56]  = 16'sd15392;
    cosine_lut[57]  = 16'sd15357;  cosine_lut[58]  = 16'sd15322;  cosine_lut[59]  = 16'sd15286;
    cosine_lut[60]  = 16'sd15250;  cosine_lut[61]  = 16'sd15213;  cosine_lut[62]  = 16'sd15175;
    cosine_lut[63]  = 16'sd15137;  cosine_lut[64]  = 16'sd15098;  cosine_lut[65]  = 16'sd15059;
    cosine_lut[66]  = 16'sd15019;  cosine_lut[67]  = 16'sd14978;  cosine_lut[68]  = 16'sd14937;
    cosine_lut[69]  = 16'sd14896;  cosine_lut[70]  = 16'sd14854;  cosine_lut[71]  = 16'sd14811;
    cosine_lut[72]  = 16'sd14768;  cosine_lut[73]  = 16'sd14724;  cosine_lut[74]  = 16'sd14680;
    cosine_lut[75]  = 16'sd14635;  cosine_lut[76]  = 16'sd14589;  cosine_lut[77]  = 16'sd14543;
    cosine_lut[78]  = 16'sd14497;  cosine_lut[79]  = 16'sd14449;  cosine_lut[80]  = 16'sd14402;
    cosine_lut[81]  = 16'sd14354;  cosine_lut[82]  = 16'sd14305;  cosine_lut[83]  = 16'sd14256;
    cosine_lut[84]  = 16'sd14206;  cosine_lut[85]  = 16'sd14155;  cosine_lut[86]  = 16'sd14104;
    cosine_lut[87]  = 16'sd14053;  cosine_lut[88]  = 16'sd14001;  cosine_lut[89]  = 16'sd13949;
    cosine_lut[90]  = 16'sd13896;  cosine_lut[91]  = 16'sd13842;  cosine_lut[92]  = 16'sd13788;
    cosine_lut[93]  = 16'sd13733;  cosine_lut[94]  = 16'sd13678;  cosine_lut[95]  = 16'sd13623;
    cosine_lut[96]  = 16'sd13567;  cosine_lut[97]  = 16'sd13510;  cosine_lut[98]  = 16'sd13453;
    cosine_lut[99]  = 16'sd13395;  cosine_lut[100] = 16'sd13337;  cosine_lut[101] = 16'sd13279;
    cosine_lut[102] = 16'sd13219;  cosine_lut[103] = 16'sd13160;  cosine_lut[104] = 16'sd13100;
    cosine_lut[105] = 16'sd13039;  cosine_lut[106] = 16'sd12978;  cosine_lut[107] = 16'sd12916;
    cosine_lut[108] = 16'sd12854;  cosine_lut[109] = 16'sd12792;  cosine_lut[110] = 16'sd12729;
    cosine_lut[111] = 16'sd12665;  cosine_lut[112] = 16'sd12601;  cosine_lut[113] = 16'sd12537;
    cosine_lut[114] = 16'sd12472;  cosine_lut[115] = 16'sd12406;  cosine_lut[116] = 16'sd12340;
    cosine_lut[117] = 16'sd12274;  cosine_lut[118] = 16'sd12207;  cosine_lut[119] = 16'sd12140;
    cosine_lut[120] = 16'sd12072;  cosine_lut[121] = 16'sd12004;  cosine_lut[122] = 16'sd11935;
    cosine_lut[123] = 16'sd11866;  cosine_lut[124] = 16'sd11797;  cosine_lut[125] = 16'sd11727;
    cosine_lut[126] = 16'sd11656;  cosine_lut[127] = 16'sd11585;  cosine_lut[128] = 16'sd11514;
    cosine_lut[129] = 16'sd11442;  cosine_lut[130] = 16'sd11370;  cosine_lut[131] = 16'sd11297;
    cosine_lut[132] = 16'sd11224;  cosine_lut[133] = 16'sd11151;  cosine_lut[134] = 16'sd11077;
    cosine_lut[135] = 16'sd11003;  cosine_lut[136] = 16'sd10928;  cosine_lut[137] = 16'sd10853;
    cosine_lut[138] = 16'sd10778;  cosine_lut[139] = 16'sd10702;  cosine_lut[140] = 16'sd10625;
    cosine_lut[141] = 16'sd10549;  cosine_lut[142] = 16'sd10471;  cosine_lut[143] = 16'sd10394;
    cosine_lut[144] = 16'sd10316;  cosine_lut[145] = 16'sd10238;  cosine_lut[146] = 16'sd10159;
    cosine_lut[147] = 16'sd10080;  cosine_lut[148] = 16'sd10001;  cosine_lut[149] = 16'sd9921;
    cosine_lut[150] = 16'sd9841;   cosine_lut[151] = 16'sd9760;   cosine_lut[152] = 16'sd9679;
    cosine_lut[153] = 16'sd9598;   cosine_lut[154] = 16'sd9516;   cosine_lut[155] = 16'sd9434;
    cosine_lut[156] = 16'sd9352;   cosine_lut[157] = 16'sd9269;   cosine_lut[158] = 16'sd9186;
    cosine_lut[159] = 16'sd9102;   cosine_lut[160] = 16'sd9019;   cosine_lut[161] = 16'sd8935;
    cosine_lut[162] = 16'sd8850;   cosine_lut[163] = 16'sd8765;   cosine_lut[164] = 16'sd8680;
    cosine_lut[165] = 16'sd8595;   cosine_lut[166] = 16'sd8509;   cosine_lut[167] = 16'sd8423;
    cosine_lut[168] = 16'sd8337;   cosine_lut[169] = 16'sd8250;   cosine_lut[170] = 16'sd8163;
    cosine_lut[171] = 16'sd8076;   cosine_lut[172] = 16'sd7988;   cosine_lut[173] = 16'sd7900;
    cosine_lut[174] = 16'sd7812;   cosine_lut[175] = 16'sd7723;   cosine_lut[176] = 16'sd7635;
    cosine_lut[177] = 16'sd7545;   cosine_lut[178] = 16'sd7456;   cosine_lut[179] = 16'sd7366;
    cosine_lut[180] = 16'sd7276;   cosine_lut[181] = 16'sd7186;   cosine_lut[182] = 16'sd7096;
    cosine_lut[183] = 16'sd7005;   cosine_lut[184] = 16'sd6914;   cosine_lut[185] = 16'sd6823;
    cosine_lut[186] = 16'sd6731;   cosine_lut[187] = 16'sd6639;   cosine_lut[188] = 16'sd6547;
    cosine_lut[189] = 16'sd6455;   cosine_lut[190] = 16'sd6363;   cosine_lut[191] = 16'sd6270;
    cosine_lut[192] = 16'sd6177;   cosine_lut[193] = 16'sd6084;   cosine_lut[194] = 16'sd5990;
    cosine_lut[195] = 16'sd5897;   cosine_lut[196] = 16'sd5803;   cosine_lut[197] = 16'sd5708;
    cosine_lut[198] = 16'sd5614;   cosine_lut[199] = 16'sd5520;   cosine_lut[200] = 16'sd5425;
    cosine_lut[201] = 16'sd5330;   cosine_lut[202] = 16'sd5235;   cosine_lut[203] = 16'sd5139;
    cosine_lut[204] = 16'sd5044;   cosine_lut[205] = 16'sd4948;   cosine_lut[206] = 16'sd4852;
    cosine_lut[207] = 16'sd4756;   cosine_lut[208] = 16'sd4660;   cosine_lut[209] = 16'sd4563;
    cosine_lut[210] = 16'sd4467;   cosine_lut[211] = 16'sd4370;   cosine_lut[212] = 16'sd4273;
    cosine_lut[213] = 16'sd4176;   cosine_lut[214] = 16'sd4078;   cosine_lut[215] = 16'sd3981;
    cosine_lut[216] = 16'sd3883;   cosine_lut[217] = 16'sd3786;   cosine_lut[218] = 16'sd3688;
    cosine_lut[219] = 16'sd3590;   cosine_lut[220] = 16'sd3492;   cosine_lut[221] = 16'sd3393;
    cosine_lut[222] = 16'sd3295;   cosine_lut[223] = 16'sd3196;   cosine_lut[224] = 16'sd3098;
    cosine_lut[225] = 16'sd2999;   cosine_lut[226] = 16'sd2900;   cosine_lut[227] = 16'sd2801;
    cosine_lut[228] = 16'sd2702;   cosine_lut[229] = 16'sd2603;   cosine_lut[230] = 16'sd2503;
    cosine_lut[231] = 16'sd2404;   cosine_lut[232] = 16'sd2305;   cosine_lut[233] = 16'sd2205;
    cosine_lut[234] = 16'sd2105;   cosine_lut[235] = 16'sd2006;   cosine_lut[236] = 16'sd1906;
    cosine_lut[237] = 16'sd1806;   cosine_lut[238] = 16'sd1706;   cosine_lut[239] = 16'sd1606;
    cosine_lut[240] = 16'sd1506;   cosine_lut[241] = 16'sd1406;   cosine_lut[242] = 16'sd1306;
    cosine_lut[243] = 16'sd1205;   cosine_lut[244] = 16'sd1105;   cosine_lut[245] = 16'sd1005;
    cosine_lut[246] = 16'sd904;    cosine_lut[247] = 16'sd804;    cosine_lut[248] = 16'sd704;
    cosine_lut[249] = 16'sd603;    cosine_lut[250] = 16'sd503;    cosine_lut[251] = 16'sd402;
    cosine_lut[252] = 16'sd302;    cosine_lut[253] = 16'sd201;    cosine_lut[254] = 16'sd101;
    cosine_lut[255] = 16'sd0;
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