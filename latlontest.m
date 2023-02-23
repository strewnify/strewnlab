
% h = geoaxes
% zoom on


% max_length = 10

for idx = 1:5

% get one set of coordinates from the user map
[lat,lon] = ginput(1);
%[name, elevation] = identifywater(lat,lon)
[ formatted, locality, state, country ] = getlocation_test(lat, lon, max_length)
end