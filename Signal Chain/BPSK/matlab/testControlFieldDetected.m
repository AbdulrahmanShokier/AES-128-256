
% read rtl output 
ControlField_string = strtrim(fileread('OutputControlField.txt'));
% convert to binary 
ControlVectorDetected = ControlField_string - '0'; 
% now reverse it
x = fliplr(ControlVectorDetected);      % fliplr done on row vector
% reshape in column 
ControlVectorDetected = reshape(x, length(ControlVectorDetected),1); 



% the used control (left is the LSB) - need to be reversed to match rtl order
Control_field = [0;0;1;1;1;0;1;1;0;1;0;0;1;1;1 ;1;0;1;1;1;1;1;0;1;0;1;0;0;0;0;1;1;0;1;0;0;0;1;1;0;0;0;1;1;1;0;1;1;0;0;0;1;0;1;0;1;0;1;1;1;1;1;0;0;0;1;0;1;0;1;0;0;0;1;0;0;1;1;1;1;0;1;1;0;1;0;0;1;1;1;0;1;0;0;0;0;1;0;1;0;1;0;1;1;1;0;0;0;1;0;1;1;1;0;0;0;1;0;1;1;1;0;0;0;1;0;1;0;0;0;0;1;1;1;0;1;1;0;1;0;0;0;0;0;0;0;0;1;1;0;0;0;1;0;0;1;0;0;0;0;0;1;1;1;0;0;0;1;0;0;0;1;1;1;0;1;0;1;0;1;0;0;1;1;0;1;1;0;0;0;0;1;1;1;1;1;0;1;1;0;1;1;1;1;1;0;0;0;0;1;0;0;0;0;0;0;1;0;0;1;1;0;0;0;0;1;0;1;1;0;0;0;0;0;1;0;0;1;0;1;1;0;1;0;0;1;1;1;0;0;1;1;0;0;1;0];

error = Control_field - ControlVectorDetected;