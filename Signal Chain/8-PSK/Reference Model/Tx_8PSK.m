clear; clc; close all;

%% ============ FIXED POINT PARAMETERS ============
DATA_WIDTH   = 16;
FRACTION     = 14;
SCALE        = 2^FRACTION;      % 16384

COEFF_WIDTH  = 16;
NUM_TAPS     = 33;
upsample_factor = 4;

%% ============ RRC COEFFICIENTS (from RTL) ============
% Symmetric filter - mirror coeff_0_32 to coeff_16
rrc_coeffs_fixed = [
     306;   % coeff_0
     144;   % coeff_1
    -268;   % coeff_2
    -629;   % coeff_3
    -556;   % coeff_4
      90;   % coeff_5
     978;   % coeff_6
    1416;   % coeff_7
     801;   % coeff_8
    -834;   % coeff_9
   -2590;   % coeff_10
   -3030;   % coeff_11
    -981;   % coeff_12
    3640;   % coeff_13
    9527;   % coeff_14
   14461;   % coeff_15
   16384;   % coeff_16 (center)
   14461;   % coeff_17
    9527;   % coeff_18
    3640;   % coeff_19
    -981;   % coeff_20
   -3030;   % coeff_21
   -2590;   % coeff_22
    -834;   % coeff_23
     801;   % coeff_24
    1416;   % coeff_25
     978;   % coeff_26
      90;   % coeff_27
    -556;   % coeff_28
    -629;   % coeff_29
    -268;   % coeff_30
     144;   % coeff_31
     306;   % coeff_32
];

% Normalize to floating point
rrc_coeffs_float = rrc_coeffs_fixed / SCALE;

%% ============ COSINE LUT (from RTL) ============
cosine_lut = zeros(1, 256);
cosine_lut_fixed = [
    16384, 16383, 16381, 16379, 16376, 16373, 16369, 16364, ...
    16359, 16353, 16347, 16340, 16332, 16324, 16315, 16305, ...
    16295, 16284, 16273, 16261, 16248, 16235, 16221, 16207, ...
    16192, 16176, 16160, 16143, 16125, 16107, 16088, 16069, ...
    16049, 16029, 16008, 15986, 15964, 15941, 15917, 15893, ...
    15868, 15843, 15817, 15791, 15763, 15736, 15707, 15679, ...
    15649, 15619, 15588, 15557, 15525, 15493, 15460, 15426, ...
    15392, 15357, 15322, 15286, 15250, 15213, 15175, 15137, ...
    15098, 15059, 15019, 14978, 14937, 14896, 14854, 14811, ...
    14768, 14724, 14680, 14635, 14589, 14543, 14497, 14449, ...
    14402, 14354, 14305, 14256, 14206, 14155, 14104, 14053, ...
    14001, 13949, 13896, 13842, 13788, 13733, 13678, 13623, ...
    13567, 13510, 13453, 13395, 13337, 13279, 13219, 13160, ...
    13100, 13039, 12978, 12916, 12854, 12792, 12729, 12665, ...
    12601, 12537, 12472, 12406, 12340, 12274, 12207, 12140, ...
    12072, 12004, 11935, 11866, 11797, 11727, 11656, 11585, ...
    11514, 11442, 11370, 11297, 11224, 11151, 11077, 11003, ...
    10928, 10853, 10778, 10702, 10625, 10549, 10471, 10394, ...
    10316, 10238, 10159, 10080, 10001,  9921,  9841,  9760, ...
     9679,  9598,  9516,  9434,  9352,  9269,  9186,  9102, ...
     9019,  8935,  8850,  8765,  8680,  8595,  8509,  8423, ...
     8337,  8250,  8163,  8076,  7988,  7900,  7812,  7723, ...
     7635,  7545,  7456,  7366,  7276,  7186,  7096,  7005, ...
     6914,  6823,  6731,  6639,  6547,  6455,  6363,  6270, ...
     6177,  6084,  5990,  5897,  5803,  5708,  5614,  5520, ...
     5425,  5330,  5235,  5139,  5044,  4948,  4852,  4756, ...
     4660,  4563,  4467,  4370,  4273,  4176,  4078,  3981, ...
     3883,  3786,  3688,  3590,  3492,  3393,  3295,  3196, ...
     3098,  2999,  2900,  2801,  2702,  2603,  2503,  2404, ...
     2305,  2205,  2105,  2006,  1906,  1806,  1706,  1606, ...
     1506,  1406,  1306,  1205,  1105,  1005,   904,   804, ...
      704,   603,   503,   402,   302,   201,   101,     0  ...
];

% cosine LUT covers 0 to 90 degrees (256 points = quarter wave)
cosine_lut = cosine_lut_fixed / SCALE;   % normalized float

%% ============ 8PSK SYMBOL MAP ============
% Gray coded 8PSK
% 3 bits per symbol
% Angles: k * 45 degrees, k = 0..7
% Symbol mapping:
%   000 -> 0°
%   001 -> 45°
%   011 -> 90°
%   010 -> 135°
%   110 -> 180°
%   111 -> 225°
%   101 -> 270°
%   100 -> 315°

gray_map = [0, 1, 3, 2, 6, 7, 5, 4];   % Gray code order
angles_deg = (0:7) * 45;               % 0,45,90,...,315 degrees

% I and Q values for each symbol (floating point)
I_map = cos(deg2rad(angles_deg));
Q_map = sin(deg2rad(angles_deg));

% Fixed point I/Q constellation points
I_map_fixed = round(I_map * SCALE);
Q_map_fixed = round(Q_map * SCALE);

fprintf('8PSK Constellation Points (Fixed Point):\n');
fprintf('Symbol | Bits | Angle | I_fixed | Q_fixed\n');
for k = 1:8
    fprintf('  %d    | %s  |  %3d° |  %6d  |  %6d\n', ...
        k-1, dec2bin(gray_map(k),3), angles_deg(k), ...
        I_map_fixed(k), Q_map_fixed(k));
end

%% ============ READ INPUT BITS ============
fid = fopen('data_bits.txt', 'r');
if fid == -1
    error('Cannot open data_bits.txt');
end
bits = fscanf(fid, '%d');
fclose(fid);
bits = bits(:)';   % make row vector

fprintf('\nTotal bits read: %d\n', length(bits));

% Pad to multiple of 3
pad_len = mod(3 - mod(length(bits), 3), 3);
bits    = [bits, zeros(1, pad_len)];
N_bits  = length(bits);
N_sym   = N_bits / 3;
fprintf('Total symbols   : %d\n', N_sym);

%% ============ BIT TO SYMBOL MAPPING ============
% Group into 3-bit words
bits_matrix = reshape(bits, 3, N_sym)';   % N_sym x 3

% Convert 3-bit groups to decimal index 0..7
sym_index = bi2de(bits_matrix, 'left-msb');   % 0..7

% Map through Gray code
gray_index = zeros(1, N_sym);
for k = 1:N_sym
    gray_index(k) = find(gray_map == sym_index(k)) - 1;
end

% Get I and Q values (floating point)
I_symbols = I_map(gray_index + 1);
Q_symbols = Q_map(gray_index + 1);

% Fixed point symbols
I_symbols_fixed = round(I_symbols * SCALE);
Q_symbols_fixed = round(Q_symbols * SCALE);

%% ============ UPSAMPLE by 4 ============
% Insert 3 zeros between each symbol (upsample factor = 4)
I_upsampled = zeros(1, N_sym * upsample_factor);
Q_upsampled = zeros(1, N_sym * upsample_factor);

I_upsampled(1:upsample_factor:end) = I_symbols_fixed;
Q_upsampled(1:upsample_factor:end) = Q_symbols_fixed;

fprintf('Upsampled length: %d\n', length(I_upsampled));

%% ============ RRC FILTER (Fixed Point FIR) ============
% Convolve with RRC coefficients
% Replicate exact RTL fixed-point multiply-accumulate behavior

function y_fixed = fir_fixed_point(x, coeffs, DATA_WIDTH, COEFF_WIDTH)
% Fixed point FIR filter matching RTL behavior
% x      - input signal (fixed point integers)
% coeffs - filter coefficients (fixed point integers)
% Accumulator width = DATA_WIDTH + COEFF_WIDTH = 32 bits
% Output is truncated back to DATA_WIDTH after >> FRACTION

    N      = length(x);
    N_taps = length(coeffs);
    y_fixed = zeros(1, N);

    for n = 1:N
        acc = int64(0);
        for k = 1:N_taps
            idx = n - k + 1;
            if idx >= 1
                acc = acc + int64(x(idx)) * int64(coeffs(k));
            end
        end
        % Truncate: shift right by FRACTION bits (14)
        y_fixed(n) = double(bitshift(acc, -14));
    end
end

fprintf('\nApplying RRC filter to I channel...\n');
I_filtered_fixed = fir_fixed_point(I_upsampled, rrc_coeffs_fixed', ...
                                    DATA_WIDTH, COEFF_WIDTH);

fprintf('Applying RRC filter to Q channel...\n');
Q_filtered_fixed = fir_fixed_point(Q_upsampled, rrc_coeffs_fixed', ...
                                    DATA_WIDTH, COEFF_WIDTH);

% Clip to 16-bit signed range
I_filtered_fixed = max(-32768, min(32767, I_filtered_fixed));
Q_filtered_fixed = max(-32768, min(32767, Q_filtered_fixed));

%% ============ WRITE OUTPUT FILES ============
% Write I samples
fid = fopen('I_samples_golden.txt', 'w');
for k = 1:length(I_filtered_fixed)
    fprintf(fid, '%d\n', I_filtered_fixed(k));
end
fclose(fid);

% Write Q samples
fid = fopen('Q_samples_golden.txt', 'w');
for k = 1:length(Q_filtered_fixed)
    fprintf(fid, '%d\n', Q_filtered_fixed(k));
end
fclose(fid);

% Write combined I Q file
fid = fopen('IQ_samples_golden.txt', 'w');
for k = 1:length(I_filtered_fixed)
    fprintf(fid, '%d %d\n', I_filtered_fixed(k), Q_filtered_fixed(k));
end
fclose(fid);

fprintf('\nOutput files written:\n');
fprintf('  I_samples_golden.txt\n');
fprintf('  Q_samples_golden.txt\n');
fprintf('  IQ_samples_golden.txt\n');

%% ============ FIGURE 1: 8PSK Constellation (TX) ============
figure(1)
plot(I_map, Q_map, 'k--', 'LineWidth', 0.8)
hold on
for k = 1:8
    plot(I_map(k), Q_map(k), 'b^', 'MarkerSize', 12, 'LineWidth', 2)
    text(I_map(k)*1.15, Q_map(k)*1.15, ...
        sprintf('%s', dec2bin(gray_map(k),3)), ...
        'FontSize', 10, 'HorizontalAlignment', 'center')
end
grid on
xlabel('I', 'FontSize', 12)
ylabel('Q', 'FontSize', 12)
title('8PSK Constellation (Gray Coded)', 'FontSize', 13)
xlim([-1.5 1.5]); ylim([-1.5 1.5])
axis square
hold off

%% ============ FIGURE 2: I and Q after RRC ============
plot_len = min(500, length(I_filtered_fixed));

figure(2)
subplot(2,1,1)
stem(1:plot_len, I_filtered_fixed(1:plot_len), 'b', 'MarkerSize', 3)
grid on
xlabel('Sample')
ylabel('Amplitude (fixed point)')
title('I Channel after RRC Filter')

subplot(2,1,2)
stem(1:plot_len, Q_filtered_fixed(1:plot_len), 'r', 'MarkerSize', 3)
grid on
xlabel('Sample')
ylabel('Amplitude (fixed point)')
title('Q Channel after RRC Filter')

%% ============ FIGURE 3: Eye Diagram I channel ============
sps        = upsample_factor;
eye_len    = 2 * sps;
n_traces   = floor(length(I_filtered_fixed) / eye_len) - 1;

figure(3)
hold on
for k = 1:min(100, n_traces)
    seg = I_filtered_fixed((k-1)*eye_len+1 : k*eye_len);
    plot(seg / SCALE, 'b', 'LineWidth', 0.5, 'Color', [0 0 1 0.2])
end
grid on
xlabel('Sample within 2-symbol window')
ylabel('Normalized Amplitude')
title('Eye Diagram - I Channel (after RRC)')
hold off

%% ============ FIGURE 4: Upsampled vs Filtered ============
plot_syms = min(20, N_sym);
plot_samp = plot_syms * upsample_factor;

figure(4)
subplot(2,1,1)
stem(1:plot_samp, I_upsampled(1:plot_samp), 'b', 'MarkerSize', 4)
grid on
xlabel('Sample')
ylabel('Fixed Point Value')
title('I Channel - After Upsampling (before RRC)')

subplot(2,1,2)
plot(1:plot_samp, I_filtered_fixed(1:plot_samp), 'r', 'LineWidth', 1.5)
grid on
xlabel('Sample')
ylabel('Fixed Point Value')
title('I Channel - After RRC Filter')

%% ============ FIGURE 5: Cosine LUT verification ============
theta_deg  = linspace(0, 90, 256);
cos_matlab = cos(deg2rad(theta_deg));

figure(5)
plot(theta_deg, cosine_lut, 'b-', 'LineWidth', 2, ...
    'DisplayName', 'RTL LUT (normalized)')
hold on
plot(theta_deg, cos_matlab, 'r--', 'LineWidth', 1.5, ...
    'DisplayName', 'MATLAB cos()')
grid on
xlabel('Angle (degrees)')
ylabel('Amplitude')
title('Cosine LUT Verification')
legend('Location', 'southwest')
hold off

fprintf('\nGolden reference complete.\n');