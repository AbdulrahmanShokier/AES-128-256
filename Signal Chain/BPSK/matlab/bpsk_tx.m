clear all; clc;

%%%  --------------------------- Parameters -------------------------------
N_Preamble = 255; % preamble length 
N_Control = 256;  % Control length
M = 1;     % modulation order
OSR = 4;

% rrc coeffs 
rrc_Coeffs = [0.00498847928955557,0.00235155002615515,-0.00436429519457765,-0.0102504630409555,-0.00906125220703628,0.00146261107473937,0.0159397856990236,0.0230767071177516,0.0130626720595367,-0.0135897614385538,-0.0422122341581480,-0.0493856648341822,-0.0159984981804697,0.0593387848584193,0.155302136611891,0.235735494392970,0.267077471545948,0.235735494392970,0.155302136611891,0.0593387848584193,-0.0159984981804697,-0.0493856648341822,-0.0422122341581480,-0.0135897614385538,0.0130626720595367,0.0230767071177516,0.0159397856990236,0.00146261107473937,-0.00906125220703628,-0.0102504630409555,-0.00436429519457765,0.00235155002615515,0.00498847928955557];
rrc_Coeffs_floating = rrc_Coeffs;
rrc_Coeffs_normalized = rrc_Coeffs_floating/max(rrc_Coeffs_floating);
rrc_Coeffs_fixed = round(rrc_Coeffs_normalized*2^14);      %now it's Q14 -> go to rtl. 

%%%---------------------- Preamble (pn-sequence)  -------------------------
preamble = [1;0;0;0;0;1;0;0;0;1;0;1;1;1;0;1;0;1;1;1;1;0;1;1;0;1;1;1;1;1;0;0;0;0;1;1;0;1;0;0;1;1;0;1;0;1;1;0;1;1;0;1;0;1;0;0;0;0;0;1;0;0;1;1;1;0;1;1;0;0;1;0;0;1;0;0;1;1;0;0;0;0;0;0;1;1;1;0;1;0;0;1;0;0;0;1;1;1;0;0;0;1;0;0;0;0;0;0;0;1;0;1;1;0;0;0;1;1;1;1;0;1;0;0;0;0;1;1;1;1;1;1;1;1;0;0;1;0;0;0;0;1;0;1;0;0;1;1;1;1;1;0;1;0;1;0;1;0;1;1;1;0;0;0;0;0;1;1;0;0;0;1;0;1;0;1;1;0;0;1;1;0;0;1;0;1;1;1;1;1;1;0;1;1;1;1;0;0;1;1;0;1;1;1;0;1;1;1;0;0;1;0;1;0;1;0;0;1;0;1;0;0;0;1;0;0;1;0;1;1;0;1;0;0;0;1;1;0;0;1;1;1;0;0;1;1;1;1;0;0;0;1;1;0;1]; 

%%%---------------------- Control generation (random for now) -------------
%control = randi([0 1], N_Control, 1); 
%control = [0;0;1;1;1;0;1;1;0;1;0;0;1;1;1 ;1;0;1;1;1;1;1;0;1;0;1;0;0;0;0;1;1;0;1;0;0;0;1;1;0;0;0;1;1;1;0;1;1;0;0;0;1;0;1;0;1;0;1;1;1;1;1;0;0;0;1;0;1;0;1;0;0;0;1;0;0;1;1;1;1;0;1;1;0;1;0;0;1;1;1;0;1;0;0;0;0;1;0;1;0;1;0;1;1;1;0;0;0;1;0;1;1;1;0;0;0;1;0;1;1;1;0;0;0;1;0;1;0;0;0;0;1;1;1;0;1;1;0;1;0;0;0;0;0;0;0;0;1;1;0;0;0;1;0;0;1;0;0;0;0;0;1;1;1;0;0;0;1;0;0;0;1;1;1;0;1;0;1;0;1;0;0;1;1;0;1;1;0;0;0;0;1;1;1;1;1;0;1;1;0;1;1;1;1;1;0;0;0;0;1;0;0;0;0;0;0;1;0;0;1;1;0;0;0;0;1;0;1;1;0;0;0;0;0;1;0;0;1;0;1;1;0;1;0;0;1;1;1;0;0;1;1;0;0;1;0];


%%%---------------------------- Modulation  -------------------------------
data_symbols = preamble;
%data_symbols = [preamble;control];    % for bpsk
symbols = real(pskmod(data_symbols,2^M));


%%%-------------------  Oversampling and pulse shaping --------------------
symbols_OSR = upsample(symbols,OSR);
symbols_OSR = symbols_OSR * 2^14;                             %make it in Q14 also
symbols_shaped = conv(symbols_OSR,rrc_Coeffs_fixed);      %root rasied cosine (pulse shaping) 

test_input_fir = symbols_OSR;              % go to the rtl 
test_output_fir = symbols_shaped;          % compare with rtl outupt 

% cmd: eyediagram(symbols_OSR,8); for OSR = 4, to show 2 symbols 

%%%------------------  Extract test_input as a test vector ------------------------
fid = fopen('FIRTest_input.txt','w');
fprintf(fid, '%04X\n', typecast(int16(test_input_fir), 'uint16'));
fclose(fid);


%%%-------------  Truncate like in rtl outptut to test rtl output  -------------------
pre_trunc = bitshift(int64(symbols_shaped),-14); % throw the least 14 significant bits

% check the range of it to test the validity for our truncation (either it exists overflow for turncated width) 
max_val = max(pre_trunc);   % should be < 2^15-1
min_val = min(pre_trunc);   % should be > -2^15  
                            % if both are ture -> can be truncated into 16
                            % bits without overflow (so correct truncation in rtl)


shaped_truncated = int16(pre_trunc);     % match 16-bit output [29:14] -> "data_out" in rtl
                                         % exact shifting and slicing to test rtl functionality

symbols_shaped_fullscale = symbols_shaped / (2^14);  % no turncation 
                                                     % to calculate the truncation error
trunc_error = symbols_shaped_fullscale - double(shaped_truncated); 
                                                     % zero truncation error!
                                              
                                                     
%%% Down sampling (good to understand it in Rx sampling stage)
num_taps = 33; 
fir_delay = (num_taps-1)/2;         % no of taps -1 / 2 





