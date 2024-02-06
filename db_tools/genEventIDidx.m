function [EventIDidx] = genEventIDidx(allowed_char)
%GENEVENTIDIDX Generate a cell array of EventID increments
% EventIDidx = genEventIDidx(EventIDidx_char) returns a cell array of 
% incrementing ID's, used in EventID, in the case of multiple events in one hour
% Supports up to 1296 additional events

% Check for duplicate characters
allowed_char_len = numel(allowed_char);
if numel(unique(allowed_char)) ~= allowed_char_len
    logformat('Unexpected duplicate characters','ERROR')
end

% Count max number of combinations
num_combs = allowed_char_len^2 + allowed_char_len;

% Generate combinations
for cnt = 1:num_combs
    if cnt <= allowed_char_len
        char1 = 'Z';
    else
        char1 = allowed_char(ceil(cnt/numel(allowed_char))-1);
    end
    char2 = allowed_char(mod(cnt-1,numel(allowed_char))+1);
    EventIDidx(cnt) = {[char1 char2]};
end

%Remove duplicate combinations, keeping preferred order where possible
[EventIDidx, ~, ~] = unique(EventIDidx,'stable');