
h = geoaxes
zoom on


% max_length = 10

for idx = 1:10

% get one set of coordinates from the user map
[lat,lon] = ginput(1);
disp([newline 'lat/lon = ' num2str(lat) ', ' num2str(lon)])
%[name, elevation] = identifywater(lat,lon)
[ location_string, locality, state, country, water_string, land_string ] = getlocation(lat, lon, 25);
%[suggestions, search_radius] = suggest_eventnames(lat,lon,9);
% [ formatted_1, ~, ~, ~ ] = getlocation(lat, lon, 32);
% [ formatted_2, ~, ~, ~ ] = getlocation(lat, lon, 15);

disp(location_string)
disp(locality)
disp(state)
disp(country)

end