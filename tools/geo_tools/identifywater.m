function [body_of_water, elevation_out_m] = identifywater(lat,lon,elevation_in_m)
%[BODY_OF_WATER, ELEVATION_CORRECTED_M] = IDENTIFYWATER(LAT,LON,ELEVATION_M) Checks if the coordinates lie in a large
%body of water.

% Test cases
% lat = [48.051380   47.923210  44.553202  41.110768 29.311052 42.716115 -16.416869 -88.296950  56.850426  41.646667 41.639164 41.582352   33.273689   33.273069   31.533710 -40.400701 41.834933 36.250313 46 -49.586743];
% lon = [-86.958136 -88.985785 -87.051492 -90.556513 34.800562 89.265739  81.352922  66.728613 -86.310351 -82.813374 49.394454 48.832864 -115.777026 -115.873951 -114.672608 -65.201076 -83.205938 -116.785840 36 -68.339719];
% iswater_check = [true false true false true false true false true false true false true false true false true false true false];

min_elevation_m = -50; % elevations below this will be considered water,if not defined as dry land

% if elevation is passed, don't call Google API
if nargin == 2
    % Get elevations from Google
    % Resolution is better if single inputs are passed

    for idx = 1:numel(lat)
        try
            elevation_in_m(idx) = getElevations(lat(idx),lon(idx),'key', getPrivate('GoogleMapsAPIkey'));
        catch
            if getSession('state','userpresent')
                logformat('Google Maps API failure.  User queried for ground elevation.','WARN')
                usersuccess = false;
                while ~usersuccess
                    user_ground = inputdlg('Elevation data not accessible. Please enter ground elevation in meters:','Google API Failure',1,{'0'});        
                    ground = str2double(cell2mat(user_ground)); 
                    if isnan(ground)
                        logformat('User entered invalid ground elevation.','ERROR')
                        usersuccess = false;
                    else
                        logformat(sprintf('User entered %f for ground elevation.',ground),'USER')
                        usersuccess = true;
                    end
                end
                clear usersuccess
            else
                logformat('Google Maps API failure.  Ground elevation defaulted to zero.','WARN')
                ground = 0;
            end
        end
    end
end

% initialize outputs
body_of_water(1:length(lat)) = {'unknown'};
elevation_out_m = elevation_in_m;

% initial corrections
body_of_water(elevation_in_m < min_elevation_m) = {'water'};
elevation_out_m(elevation_in_m < min_elevation_m) = 0;

warning('off','MATLAB:table:RowsAddedExistingVars')

% Check known bodies of water
load coastlines
db_features = table;

db_features.body_name(1) = {'Lake Superior'};
db_features.surface_m(1) = 183.185;
db_features.body_lat(1) = {coastlat(2528:2568)};
db_features.body_lon(1) = {coastlon(2528:2568)};

db_features.body_name(2) = {'Lake Huron/Michigan'};
db_features.surface_m(2) = 175.87;
db_features.body_lat(2) = {coastlat(2570:2652)};
db_features.body_lon(2) = {coastlon(2570:2652)};

db_features.body_name(3) = {'Lake Erie'};
db_features.surface_m(3) = 173.126;
db_features.body_lat(3) = {coastlat(2661:2678)};
db_features.body_lon(3) = {coastlon(2661:2678)};

db_features.body_name(4) = {'Lake Ontario'};
db_features.surface_m(4) = 74.066;
db_features.body_lat(4) = {coastlat(2680:2695)};
db_features.body_lon(4) = {coastlon(2680:2695)};

db_features.body_name(5) = {'Lake Victoria'};
db_features.surface_m(5) = 1136;
db_features.body_lat(5) = {coastlat(6705:6724)};
db_features.body_lon(5) = {coastlon(6705:6724)};

db_features.body_name(6) = {'Caspian Sea'};
db_features.surface_m(6) = -27;
db_features.body_lat(6) = {coastlat(6886:6992)};
db_features.body_lon(6) = {coastlon(6886:6992)};

warning('on','MATLAB:table:RowsAddedExistingVars')

% Check for each body of water
for idx = 1:size(db_features,1)
    body_match = inpolygon(lat,lon,db_features.body_lat{idx},db_features.body_lon{idx}) & (elevation_in_m < db_features.surface_m(idx) | elevation_in_m == 0);
    body_of_water(body_match) = db_features.body_name(idx);
    elevation_out_m(body_match) = db_features.surface_m(idx);
    clear body_lat
    clear body_lon
    clear body_match
end

% Check known dry land
% Check for known areas with negative elevation
DeadSea = lat > 30 & lat < 33 & lon > 35.15 & lon < 36;                         % -430m
Turfan = lat > 42 & lat < 44 & lon > 88 & lon < 93;                             % -154m
Qattara = lat > 28.5 & lat < 30.5 & lon > 25 & lon < 29;                        % -133m

Danakil_lat = [40.192146 39.629993 39.947817 42.210469 40.901599 40.192146];    % -125m
Danakil_lon = [14.868281 14.909525 12.176209 12.730487 14.524305 14.868281];
Danakil = inpolygon(lat,lon,Danakil_lat,Danakil_lon);

Badwater = lat > 35 & lat < 37 & lon > -118 & lon < -116;                       % -86m
LagunaCarbon = lat > -49.7 & lat < -49.3 & lon > -69 & lon < -68;               % -105m
BajoDelGualicho = lat > -40.6 & lat < -40 & lon > -65.9 & lon < -64.6;          % -72m
SaltonSink = lat > 32 & lat < 34 & lon > -116.5 & lon < -114;                   % -70m


known_dryland = DeadSea | Turfan | Qattara | Danakil | Badwater | LagunaCarbon | BajoDelGualicho | SaltonSink;
%body_of_water(known_dryland) = {'depression'};
elevation_out_m(known_dryland) = elevation_in_m(known_dryland);

% if known body of water or elevation is less than min elevation and not known dry land 
%iswater_result = ~strcmp(body_of_water,'none') | ((elevation_in_m < min_elevation_m) & ~known_dryland);

% troubleshooting test cases
% C = iswater_check ~= iswater_result
% C = [C;zeros(1,length(lat));zeros(1,length(lat))]';
% geoscatter(lat,lon,10,C)
