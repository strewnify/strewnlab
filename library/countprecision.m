function [digits] = countprecision(number)
%COUNTPRECISION Count the number of significant digits after the decimal point

% number of digits to check
% should be less than ~12 for typical floating point numbers
precision = 10;

text_num = sprintf(['%0.' num2str(precision) 'f'],number);
text_len = length(text_num);

digits = 0;
lastfound = false;
for idx = text_len:-1:1
    
    if text_num(idx) == '.'
        break
    elseif ~lastfound && text_num(idx) ~= '0'
        digits = digits + 1;
        lastfound = true;
    elseif lastfound
        digits = digits + 1;
    end
end

if digits >= precision
    warning('Digits may exceed precision.')
end