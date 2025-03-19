function [ suggestions, search_radius ] = suggest_eventnames(lat,lon,radius_max_km)
% SUGGEST_EVENTNAMES suggests nasmes for an event, based on nearby locality names.
% [Suggestions] = suggest_eventnames(lat,lon,radius_max_km)
% This function calls GETLOCATION multiple times, and Google charges 
% $5 per 1000 requests, so please do not abuse this function!

% Max calls to GETLOCATION, to prevent charges ($)
max_apicalls = 15;

% Max string length for location from GETLOCATION
max_stringlength = 64;

% Initialize ellipsoid
planet = getPlanet();

% Configure steps
radius_step_km = 3; %km steps in radius
circ_step_km = 2*radius_step_km*pi/4; %km steps along circumference

apicalls = 0; % init counter

% Step through radii
stopnow = false;
flipper = false;
search_radii = 0:radius_step_km:radius_max_km;
if (radius_max_km - search_radii(end)) > (radius_step_km/2)
    search_radii = [search_radii radius_max_km];
end

for radius_km = search_radii

    flipper = ~flipper;
    circumference_km = pi*2*radius_km;
    az_step = 360*circ_step_km/circumference_km;
    if flipper
        az_steps = 0:az_step:360;
    else
        az_steps = mean([0,az_step]):az_step:360;
    end
    numsteps = numel(az_steps);

    % Step around circumference
    radius_m = radius_km.*1000;
    for az_i = 1:numsteps
        
        apicalls = apicalls + 1;    
        [latout(apicalls),lonout(apicalls)] = reckon(lat,lon,radius_m,az_steps(az_i),getPlanet('ellipsoid_m'));

        % Get location info from Google
        [ out1, out2, out3, out4, out5, out6 ] = getlocation(latout(az_i),lonout(az_i),max_stringlength);

        %Store output chars to cell arrays
        location_string(apicalls) = {out1};
        locality(apicalls) = {out2};
        state(apicalls) = {out3};
        country(apicalls) = {out4};
        water_string(apicalls) = {out5};
        land_string(apicalls) = {out6};
        
        location_string_rad(apicalls) = radius_km;
        locality_rad(apicalls) = radius_km;
        state_rad(apicalls) = radius_km;
        country_rad(apicalls) = radius_km;
        water_string_rad(apicalls) = radius_km;
        land_string_rad(apicalls) = radius_km;
        
        if apicalls >= max_apicalls 
            warning(sprintf('Google geolocation API called %.0f times. Max limit reached.',apicalls))
            stopnow = true;
            break
        end
        
        % only run once on radius zero (input location)
        if radius_km == 0
            break
        end
    end       
    if stopnow
        break;
    end
end

% Return suggestions
loc_rads = [locality_rad land_string_rad water_string_rad];
[suggestions, IA, ~] = unique([locality extractBefore(land_string,',') water_string]);
search_radius = loc_rads(IA);
delete_idx = matches(suggestions,{''}) | matches(suggestions,{'water'});
suggestions(delete_idx) = [];
search_radius(delete_idx) = [];

% Sort output, by closest first
[search_radius,I] = sort(search_radius);
suggestions = suggestions(I);

% transpose to vertical
suggestions = suggestions';
search_radius = search_radius';



