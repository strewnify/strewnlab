function [loc_string] = encodelocation(LAT,LONG)
% ENCODE LOCATION
% Adapted from DEC2BAS, Copyright 1984-2016 The MathWorks, Inc.
% Original by Douglas M. Schwarz, Eastman Kodak Company, 1996.
b = 62;

latnum = (LAT + 90)

d = d(:);
if ~(isnumeric(d) || ischar(d)) || any(d ~= floor(d)) || any(d < 0) || any(d > flintmax)
    error(message('MATLAB:dec2base:FirstArg'));
end
if ~isscalar(b) || ~(isnumeric(b) || ischar(b)) || b ~= floor(b) || b < 2 || b > 62
    error(message('MATLAB:dec2base:SecondArg'));
end

d = double(d);
b = double(b);
n = max(1,round(log2(max(d)+1)/log2(b)));
while any(b.^n <= d)
    n = n + 1;
end

s(:,n) = rem(d,b);
% any(d) must come first as it short circuits for empties
while any(d) && n >1
    n = n - 1;
    d = floor(d/b);
    s(:,n) = rem(d,b);
end
symbols = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
s = reshape(symbols(s + 1),size(s));
