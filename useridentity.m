function [ip_address] = useridentity
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

% get IPv4 address
[~, result] = system('ipconfig');
ip_delimiter = 'IPv4 Address. . . . . . . . . . . : ';
offset = length(ip_delimiter);
start_idx = findstr(result,ip_delimiter)+offset;

% line break after delimiter
line_breaks = findstr(result(start_idx:end),char(10));

end_idx = start_idx + line_breaks(1) - 2;

ip_address = result(start_idx:end_idx);



