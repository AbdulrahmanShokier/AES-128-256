clc;
clear;

POLY     = uint32(hex2dec('04C11DB7'));
CRC_INIT = uint32(hex2dec('FFFFFFFF'));

% ASCII string
msg = '123456789';

% Convert to uint8 ASCII bytes
data_bytes = uint8(msg);

crc = CRC_INIT;

% ----------------------------------------------------------
% Process byte-by-byte
% MSB FIRST
% ----------------------------------------------------------
for k = 1:length(data_bytes)

    byte = data_bytes(k);

    % Process 8 bits MSB first
    for bit_idx = 7:-1:0

        data_bit = bitget(byte, bit_idx + 1);

        crc_msb = bitget(crc, 32);

        fb = xor(crc_msb, data_bit);

        % Shift LEFT
        crc = bitshift(crc,1);

        % Keep only 32 bits
        crc = bitand(crc, uint32(hex2dec('FFFFFFFF')));

        % Apply polynomial
        if fb
            crc = bitxor(crc, POLY);
        end

    end
end

fprintf('CRC = 0x%08X\n', crc);