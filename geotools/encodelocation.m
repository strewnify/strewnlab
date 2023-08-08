function [ encoded_location ] = encodelocation( LAT, LONG, precision, cipher_length)
% [ ENCODED_TEXT ] = ENCODE( LAT, LONG, CIPHER_LENGTH ) Encode location

% Supported characters
supported_char = '1234567890abcdefghijklmnopqrstuvwxyz';

% Generate key from seed
wrapLAT = wrapTo180(round(LAT,precision)); % round to 3 decimal places
wrapLONG = wrapTo360(round(LONG,precision)); % round to 3 decimal places
seed = (wrapTo180(LAT)+wrapTo360(LONG)).*10^precision;
stream = RandStream('twister','Seed',seed);
key = randi(stream,numel(supported_char),[1 cipher_length]);

% Encoding Algorithm
for text_i = 1:cipher_length
    encoded_location(text_i) = supported_char(key(text_i));         
end