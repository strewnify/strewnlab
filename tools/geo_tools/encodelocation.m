function [ encoded_location ] = encodelocation(LAT, LONG)
% [ ENCODED_TEXT ] = ENCODE( LAT, LONG, CIPHER_LENGTH ) Encode location

% Supported characters
supported_char = '1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

lat_cipher_length = 2;
lon_cipher_length = 3;

% Encode LAT 
% Generate key from seed
seed = (LAT + 90).*10^7;
stream = RandStream('twister','Seed',seed);
key = randi(stream,numel(supported_char),[1 lat_cipher_length]);

% Encoding Algorithm
for text_i = 1:lat_cipher_length
    encoded_lat(text_i) = supported_char(key(text_i));         
end

% Encode LON
seed = (LONG + 180).*10^7;
stream = RandStream('twister','Seed',seed);
key = randi(stream,numel(supported_char),[1 lon_cipher_length]);

% Encoding Algorithm
for text_i = 1:lon_cipher_length
    encoded_lon(text_i) = supported_char(key(text_i));         
end

encoded_location = [encoded_lat encoded_lon];