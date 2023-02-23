
% h = geoaxes
% zoom on

for idx = 1:5

% get one set of coordinates from the user map
[lat,lon] = ginput(1);
%[name, elevation] = identifywater(lat,lon)
[ formatted, locality, state, country ] = getlocation_test(lat, lon)
end