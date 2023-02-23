
% h = geoaxes
% zoom on


% max_length = 10

for idx = 1:100

% get one set of coordinates from the user map
[lat,lon] = ginput(1);
disp([newline 'lat/lon = ' num2str(lat) ', ' num2str(lon)])
%[name, elevation] = identifywater(lat,lon)
[ formatted, ~, ~, ~ ] = getlocation(lat, lon, inf);
% [ formatted_1, ~, ~, ~ ] = getlocation(lat, lon, 32);
% [ formatted_2, ~, ~, ~ ] = getlocation(lat, lon, 15);

disp(formatted)
% disp(formatted_1)
% disp(formatted_2)

end