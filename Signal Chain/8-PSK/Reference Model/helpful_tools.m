%% Decimal Integer → Q1.14 → Actual Decimal Value
% Just change this number:
val = 14206;

% Convert to 16-bit signed binary
if val >= 0
    bin_str = dec2bin(val, 16);
else
    bin_str = dec2bin(val + 2^16, 16);  % Two's complement
end

% Q1.14 interpretation
actual = val / 2^14;

% Display
fprintf('Integer     : %d\n', val);
fprintf('Binary      : %s\n', bin_str);
fprintf('Q1.14 format: %s %s . %s\n', bin_str(1), bin_str(2), bin_str(3:16));
fprintf('Actual value: %.10f\n', actual);