clear; clc; close all;

%% ============ FIXED POINT PARAMETERS ============
DATA_WIDTH   = 16;
FRACTION     = 14;
SCALE        = 2^FRACTION;
COEFF_WIDTH  = 16;
NUM_TAPS     = 33;
upsample_factor = 4;

%% ============ RRC COEFFICIENTS (from RTL) ============
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

rrc_coeffs_float = rrc_coeffs_fixed / SCALE;

%% ============ COSINE LUT (from RTL) ============
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

cosine_lut = cosine_lut_fixed / SCALE;

%% ============ 8PSK SYMBOL MAP ============
gray_map   = [0, 1, 3, 2, 6, 7, 5, 4];
angles_deg = (0:7) * 45;

I_map = cos(deg2rad(angles_deg));
Q_map = sin(deg2rad(angles_deg));

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

bits = [];
line = fgetl(fid);
while ischar(line)
    line = strtrim(line);
    if length(line) == 3
        for k = 1:3
            bits(end+1) = str2double(line(k));
        end
    end
    line = fgetl(fid);
end
fclose(fid);

bits   = bits(:)';
N_bits = length(bits);
N_sym  = N_bits / 3;

fprintf('\nTotal bits read : %d\n', N_bits);
fprintf('Total symbols   : %d\n',  N_sym);

%% ============ BIT TO SYMBOL MAPPING ============
bits_matrix = reshape(bits, 3, N_sym)';
sym_index   = bi2de(bits_matrix, 'left-msb');

gray_index = zeros(1, N_sym);
for k = 1:N_sym
    gray_index(k) = find(gray_map == sym_index(k)) - 1;
end

I_symbols = I_map(gray_index + 1);
Q_symbols = Q_map(gray_index + 1);

I_symbols_fixed = round(I_symbols * SCALE);
Q_symbols_fixed = round(Q_symbols * SCALE);

%% ============ UPSAMPLE by 4 ============
I_upsampled = zeros(1, N_sym * upsample_factor);
Q_upsampled = zeros(1, N_sym * upsample_factor);

I_upsampled(1:upsample_factor:end) = I_symbols_fixed;
Q_upsampled(1:upsample_factor:end) = Q_symbols_fixed;

fprintf('Upsampled length: %d\n', length(I_upsampled));

%% ============ RRC FILTER ============
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
fid = fopen('I_samples_golden.txt', 'w');
for k = 1:length(I_filtered_fixed)
    fprintf(fid, '%d\n', I_filtered_fixed(k));
end
fclose(fid);

fid = fopen('Q_samples_golden.txt', 'w');
for k = 1:length(Q_filtered_fixed)
    fprintf(fid, '%d\n', Q_filtered_fixed(k));
end
fclose(fid);

fid = fopen('IQ_samples_golden.txt', 'w');
for k = 1:length(I_filtered_fixed)
    fprintf(fid, '%d %d\n', I_filtered_fixed(k), Q_filtered_fixed(k));
end
fclose(fid);

fprintf('\nOutput files written:\n');
fprintf('  I_samples_golden.txt\n');
fprintf('  Q_samples_golden.txt\n');
fprintf('  IQ_samples_golden.txt\n');

%% ============ ALL FIGURES IN TABBED WINDOW ============
fig = figure('Name', '8PSK Transmitter Analysis', ...
             'NumberTitle', 'off', ...
             'Units', 'normalized', ...
             'OuterPosition', [0 0 1 1]);

tabgp = uitabgroup(fig, 'Units', 'normalized', 'Position', [0 0 1 1]);

% --------------------------------------------------------
% TAB 1: 8PSK Constellation
% --------------------------------------------------------
tab1 = uitab(tabgp, 'Title', '8PSK Constellation');
ax1  = axes('Parent', tab1);

plot(ax1, I_map, Q_map, 'k--', 'LineWidth', 0.8)
hold(ax1, 'on')
for k = 1:8
    plot(ax1, I_map(k), Q_map(k), 'b^', 'MarkerSize', 12, 'LineWidth', 2)
    text(I_map(k)*1.15, Q_map(k)*1.15, ...
        sprintf('%s', dec2bin(gray_map(k),3)), ...
        'FontSize', 10, 'HorizontalAlignment', 'center', 'Parent', ax1)
end
grid(ax1, 'on')
xlabel(ax1, 'I', 'FontSize', 12)
ylabel(ax1, 'Q', 'FontSize', 12)
title(ax1, '8PSK Constellation (Gray Coded)', 'FontSize', 13)
xlim(ax1, [-1.5 1.5])
ylim(ax1, [-1.5 1.5])
axis(ax1, 'square')
hold(ax1, 'off')

% --------------------------------------------------------
% TAB 2: I and Q after RRC
% --------------------------------------------------------
tab2     = uitab(tabgp, 'Title', 'I & Q after RRC');
plot_len = min(500, length(I_filtered_fixed));

ax2a = subplot(2, 1, 1, 'Parent', tab2);
stem(ax2a, 1:plot_len, I_filtered_fixed(1:plot_len), 'b', ...
    'MarkerSize', 2, 'LineWidth', 0.5)
grid(ax2a, 'on')
xlabel(ax2a, 'Sample')
ylabel(ax2a, 'Amplitude (fixed point)')
title(ax2a, 'I Channel after RRC Filter')

ax2b = subplot(2, 1, 2, 'Parent', tab2);
stem(ax2b, 1:plot_len, Q_filtered_fixed(1:plot_len), 'r', ...
    'MarkerSize', 2, 'LineWidth', 0.5)
grid(ax2b, 'on')
xlabel(ax2b, 'Sample')
ylabel(ax2b, 'Amplitude (fixed point)')
title(ax2b, 'Q Channel after RRC Filter')

% --------------------------------------------------------
% TAB 3: Eye Diagram I Channel
% --------------------------------------------------------
tab3     = uitab(tabgp, 'Title', 'Eye Diagram I');
ax3      = axes('Parent', tab3);
sps      = upsample_factor;
eye_len  = 2 * sps;
delay    = floor(NUM_TAPS / 2);
I_eye    = I_filtered_fixed(delay+1:end) / SCALE;
n_traces = floor(length(I_eye) / eye_len);

hold(ax3, 'on')
for k = 1:min(150, n_traces)
    seg = I_eye((k-1)*eye_len+1 : k*eye_len);
    plot(ax3, 0:eye_len-1, seg, 'Color', [0 0.4 1 0.15], 'LineWidth', 0.8)
end
grid(ax3, 'on')
xlabel(ax3, 'Sample within 2-symbol window')
ylabel(ax3, 'Normalized Amplitude')
title(ax3, 'Eye Diagram - I Channel (after RRC)')
xlim(ax3, [0 eye_len-1])
hold(ax3, 'off')

% --------------------------------------------------------
% TAB 4: Eye Diagram Q Channel
% --------------------------------------------------------
tab4  = uitab(tabgp, 'Title', 'Eye Diagram Q');
ax4   = axes('Parent', tab4);
Q_eye = Q_filtered_fixed(delay+1:end) / SCALE;

hold(ax4, 'on')
for k = 1:min(150, n_traces)
    seg = Q_eye((k-1)*eye_len+1 : k*eye_len);
    plot(ax4, 0:eye_len-1, seg, 'Color', [1 0.1 0.1 0.15], 'LineWidth', 0.8)
end
grid(ax4, 'on')
xlabel(ax4, 'Sample within 2-symbol window')
ylabel(ax4, 'Normalized Amplitude')
title(ax4, 'Eye Diagram - Q Channel (after RRC)')
xlim(ax4, [0 eye_len-1])
hold(ax4, 'off')

% --------------------------------------------------------
% TAB 5: Upsampled vs Filtered
% --------------------------------------------------------
tab5      = uitab(tabgp, 'Title', 'Upsample vs RRC');
plot_syms = min(20, N_sym);
plot_samp = plot_syms * upsample_factor;

ax5a = subplot(2, 1, 1, 'Parent', tab5);
stem(ax5a, 1:plot_samp, I_upsampled(1:plot_samp), 'b', 'MarkerSize', 4)
grid(ax5a, 'on')
xlabel(ax5a, 'Sample')
ylabel(ax5a, 'Fixed Point Value')
title(ax5a, 'I Channel - After Upsampling (before RRC)')

ax5b = subplot(2, 1, 2, 'Parent', tab5);
plot(ax5b, 1:plot_samp, I_filtered_fixed(1:plot_samp), 'r', 'LineWidth', 1.5)
grid(ax5b, 'on')
xlabel(ax5b, 'Sample')
ylabel(ax5b, 'Fixed Point Value')
title(ax5b, 'I Channel - After RRC Filter')

% --------------------------------------------------------
% TAB 6: Cosine LUT Verification
% --------------------------------------------------------
tab6       = uitab(tabgp, 'Title', 'Cosine LUT');
ax6        = axes('Parent', tab6);
theta_deg  = linspace(0, 90, 256);
cos_matlab = cos(deg2rad(theta_deg));

plot(ax6, theta_deg, cosine_lut, 'b-', 'LineWidth', 2, ...
    'DisplayName', 'RTL LUT (normalized)')
hold(ax6, 'on')
plot(ax6, theta_deg, cos_matlab, 'r--', 'LineWidth', 1.5, ...
    'DisplayName', 'MATLAB cos()')
grid(ax6, 'on')
xlabel(ax6, 'Angle (degrees)')
ylabel(ax6, 'Amplitude')
title(ax6, 'Cosine LUT Verification')
legend(ax6, 'Location', 'southwest')
hold(ax6, 'off')

fprintf('\nGolden reference complete.\n');

%% ============ FUNCTION AT END OF SCRIPT ============  ← FIXED
function y_fixed = fir_fixed_point(x, coeffs, DATA_WIDTH, COEFF_WIDTH)
    N       = length(x);
    N_taps  = length(coeffs);
    y_fixed = zeros(1, N);

    for n = 1:N
        acc = int64(0);
        for k = 1:N_taps
            idx = n - k + 1;
            if idx >= 1
                acc = acc + int64(x(idx)) * int64(coeffs(k));
            end
        end
        y_fixed(n) = double(bitshift(acc, -14));
    end
end