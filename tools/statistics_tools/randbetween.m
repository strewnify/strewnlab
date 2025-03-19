function [ random ] = randbetween( min, max, count )
%RANDBETWEEN(MIN, MAX)    Generate random number between min and max.


% Check array inputs
if numel(min) > 1 || numel(max) > 1  
    error('Inputs must be vectors of equal size')
end

% return 1 number, if no count is given
if nargin == 2
    count = 1;
end

% Swap min and max values, if needed
if max < min
    temp = max;
    max = min;
    min = temp;
end

random = min + (max-min).*rand(count,1);

end

