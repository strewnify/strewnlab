function [LON] = unwrapLON(LON)
%remove jumps in longitude for mapping display

for idx = 2:numel(LON)
    if (LON(idx)-LON(idx-1)) > 300
        LON(idx) = LON(idx) - 360;
    elseif (LON(idx)-LON(idx-1)) < -300
        LON(idx) = LON(idx) + 360;
    end
end


