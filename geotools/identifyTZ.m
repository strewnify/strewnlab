function [time_zones] = identifyTZ(lat,lon)

% initialize outputs
time_zones(1:length(lat)) = {'unknown'};
elevation_out_m = elevation_in_m;

% initial corrections
time_zones(elevation_in_m < min_elevation_m) = {'water'};
elevation_out_m(elevation_in_m < min_elevation_m) = 0;

warning('off','MATLAB:table:RowsAddedExistingVars')

% Create timezones
load coastlines
db_zones = table;

db_zones.tz_name(1) = {'EDT'};
db_zones.surface_m(1) = 183.185;
db_zones.body_lat(1) = {coastlat(2528:2568)};
db_zones.body_lon(1) = {coastlon(2528:2568)};

db_zones.tz_name(2) = {'Lake Huron/Michigan'};
db_zones.surface_m(2) = 175.87;
db_zones.tz_lat(2) = {coastlat(2570:2652)};
db_zones.tz_lon(2) = {coastlon(2570:2652)};

db_zones.tz_name(3) = {'Lake Erie'};
db_zones.surface_m(3) = 173.126;
db_zones.tz_lat(3) = {coastlat(2661:2678)};
db_zones.tz_lon(3) = {coastlon(2661:2678)};

db_zones.tz_name(4) = {'Lake Ontario'};
db_zones.surface_m(4) = 74.066;
db_zones.tz_lat(4) = {coastlat(2680:2695)};
db_zones.tz_lon(4) = {coastlon(2680:2695)};

db_zones.tz_name(5) = {'Lake Victoria'};
db_zones.surface_m(5) = 1136;
db_zones.tz_lat(5) = {coastlat(6705:6724)};
db_zones.tz_lon(5) = {coastlon(6705:6724)};

db_zones.tz_name(6) = {'Caspian Sea'};
db_zones.surface_m(6) = -27;
db_zones.tz_lat(6) = {coastlat(6886:6992)};
db_zones.tz_lon(6) = {coastlon(6886:6992)};

warning('on','MATLAB:table:RowsAddedExistingVars')

% Check for each timezone
for idx = 1:size(db_zones,1)
    tz_match = inpolygon(lat,lon,db_zones.tz_lat{idx},db_zones.tz_lon{idx}) & (elevation_in_m < db_zones.surface_m(idx) | elevation_in_m == 0);
    time_zones(tz_match) = db_zones.tz_name(idx);
    elevation_out_m(tz_match) = db_zones.surface_m(idx);
    clear tz_lat
    clear tz_lon
    clear tz_match
end

