function [ random ] = randbetween( min, max )
%RANDBETWEEN(MIN, MAX)    Generate random number between min and max.

if max < min
    temp = max;
    max = min;
    min = temp;
end

random = min + (max-min)*rand();
end

