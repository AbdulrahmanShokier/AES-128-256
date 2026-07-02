clc;
clear;
close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

M = 16;
scale = 2^14;

shifts = [0 1 5];      % degrees

fid = fopen('iq_vectors.txt','w');

if(fid==-1)
    error('Cannot create iq_vectors.txt');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate vectors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for s = 1:length(shifts)

    shift = shifts(s);

    for k = 0:M-1

        angle = k*360/M + shift;

        I = cosd(angle);
        Q = sind(angle);

        I_fixed = round(I*scale);
        Q_fixed = round(Q*scale);

        % Saturation
        I_fixed = max(min(I_fixed,32767),-32768);
        Q_fixed = max(min(Q_fixed,32767),-32768);

        fprintf(fid,"%d %d\n",I_fixed,Q_fixed);

    end

end

fclose(fid);

disp('iq_vectors.txt generated successfully.');