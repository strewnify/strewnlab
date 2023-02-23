function [ location_string, locality, state, country ] = getlocation_test(lat,lon)
% LOCATION = GETLOCATION( LATITUDE, LONGITUDE )     Query Google Maps
% reverse geocoding service to determine the locality of a set of
% coordinates.  Google charges $5 per 1000 requests, so please do not abuse
% this function.

% load Google Maps API
loadprivate

disp([newline 'lat/lon = ' num2str(lat) ', ' num2str(lon)])

try
    location_raw = webread(['https://maps.googleapis.com/maps/api/geocode/json?latlng=' num2str(lat) ',' num2str(lon) '&key=' GoogleMapsAPIkey]);
catch
    error('Google Maps reverse geocoding failed, check internet connection and try again.')
end

search_params = {'country' 'locality' 'administrative_area_level_1' 'administrative_area_level_2' 'administrative_area_level_3' 'administrative_area_level_4'};

% prefill output struct
output = struct;
for param_i = 1:numel(search_params)
    output.(search_params{param_i}) = char;
end
output.water = char;
output.formatted = char;

% Identify large bodies of water
[body_of_water,elevation_out] = identifywater(lat,lon);   
if ~strcmp(body_of_water,'unknown')
    output.water = body_of_water{1};
end

% fix cell structure for single results
if strcmp(class(location_raw.results),'struct')
    location_raw.results = {location_raw.results};
end


% check each result
for res_i = 1:size(location_raw.results,1)

    % check type of each address component
    for comp_i = 1:size(location_raw.results{res_i}.address_components,1)

        % if political data exists
        if size(location_raw.results{res_i}.address_components(comp_i).types,1) == 2 &&...
                strcmp(location_raw.results{res_i}.address_components(comp_i).types{2},'political')

            % store formatted address
            if isempty(output.formatted)
                output.formatted = location_raw.results{res_i}.formatted_address;
            end

            % check for search parameter matches
            found_i = matches(search_params,location_raw.results{res_i}.address_components(comp_i).types{1});

            % if search parameter found, store to found data
            if any(found_i) && isempty(output.(search_params{found_i}))
                output.(search_params{found_i}) = location_raw.results{res_i}.address_components(comp_i).long_name; 
            end
        end
    end 
end
            
% Country specific formatting
if ~isempty(output.country)
    switch output.country
        case 'United States'
            if ~isempty(output.formatted)
               output.formatted = regexprep(output.formatted, '\d[0-9_]+\d', char(8));
            end
            
    end
end

% Find shortest administrative region name
shortadmin = char;

adminlengths = [strlength(output.administrative_area_level_2) strlength(output.administrative_area_level_3) strlength(output.administrative_area_level_4)];
shortadmin_length = min(adminlengths(adminlengths>0));
if ~isempty(shortadmin_length)
    adminshortest = find(adminlengths == shortadmin_length,1);
    switch adminshortest
        case 1
            output.shortadmin = output.administrative_area_level_2;
        case 2
            output.shortadmin = output.administrative_area_level_3;
        case 3
            output.shortadmin = output.administrative_area_level_4;
    end
end

% Arbitrate parameters for formatted location
formatstrings = cell(0); % empty cell array

% Water location
if ~isempty(output.water)
    formatstrings = {output.water};

% Land location
else    
    if ~isempty(output.locality)
        formatstrings = [formatstrings {output.locality}];
    end
    if ~isempty(output.administrative_area_level_1)
        formatstrings = [formatstrings {output.administrative_area_level_1}];
    end
    if ~isempty(output.country)
        formatstrings = [formatstrings {output.country}];
    end    

    % if the array is still empty, put something in it
    if isempty(formatstrings)
        formatstrings = [formatstrings {output.formatted}];
    end
end

% Join strings with comma delimiter
formatjoined = join(formatstrings,', ');

% Output parameters
location_string = shorten_name(formatjoined{1});
locality = output.locality;
state = output.administrative_area_level_1;
country = output.country;

% Test output display
% output

end

function [new_name] = shorten_name(old_name)
% Shorten long names by removing common district names

    old_name = regexprep(old_name, 'State of ', '');
    old_name = regexprep(old_name, ' District', '');
    old_name = regexprep(old_name, ' Region', '');
    old_name = regexprep(old_name, ' Oblast', '');
    old_name = regexprep(old_name, ' Province', '');
    old_name = regexprep(old_name, ' Governorate', '');
    old_name = regexprep(old_name, ' Voivodeship', '');
    old_name = regexprep(old_name, ' Municipality', '');
    old_name = regexprep(old_name, 'Haixi Mongol and Tibetan Autonomous Prefecture', 'Qaidam'); % preserve order
    old_name = regexprep(old_name, '  Autonomous Prefecture', ''); % preserve order
    old_name = regexprep(old_name, ' Municipality', '');
    new_name = old_name;
end
