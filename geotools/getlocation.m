function [ location_string, locality, state, country, water_string, land_string ] = getlocation(lat,lon,max_length)
% LOCATION = GETLOCATION( LATITUDE, LONGITUDE )     Query Google Maps
% reverse geocoding service to determine the locality of a set of
% coordinates.  Google charges $5 per 1000 requests, so please do not abuse
% this function.

% load Google Maps API
loadprivate

if nargin == 2
    max_length = 32;
end

%disp([newline 'lat/lon = ' num2str(lat) ', ' num2str(lon)])

if length(lat) > 1 || length(lon) > 1
    error('Vector input unsupported, single location only')
end

% Check for invalid coordinates
if ~islat(lat) || ~islong(lon)
    logformat(sprintf('Invalid coordinates ''%2.1d, %2.1d'' provided for geocoding. ',lat,lon),'WARN')
    location_string = '-';
    locality = '-';
    state = '-';
    country = '-';
    water_string = '-';
    land_string = '-';
    
% Geocode location
else
    try
        location_raw = webread(['https://maps.googleapis.com/maps/api/geocode/json?latlng=' num2str(lat) ',' num2str(lon) '&key=' getPrivate('GoogleMapsAPIkey')]);
    catch
        logformat('Google Maps reverse geocoding failed, check internet connection and try again.','ERROR')
    end

    search_params = {'country' 'locality' 'administrative_area_level_1' 'administrative_area_level_2' 'administrative_area_level_3' 'administrative_area_level_4'};

    % prefill output struct
    output = struct;
    for param_i = 1:numel(search_params)
        output.(search_params{param_i}) = char;
        output.([search_params{param_i} '_short']) = char;
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

                % if search parameter found and the characters are supported (not Arabic or other unicode text), store to found data
                % set to 128, to support ASCII only
                % set to 564, to support most characters
                % set to inf, to support all characters, including Arabic, Chinese, etc
                % (to support all characters, remove the removediacritics function from code below)
                unicode_max = 564;

                if any(found_i) && isempty(output.(search_params{found_i}))

                    % remove diacritics from long name
                    test_longname = removediacritics(location_raw.results{res_i}.address_components(comp_i).long_name); 

                    % if all ascii characters after removing diacritics
                    if all(test_longname < unicode_max) 
                        output.(search_params{found_i}) = test_longname;                     
                    end

                    % remove diacritics from short name
                    test_shortname = removediacritics(location_raw.results{res_i}.address_components(comp_i).short_name);

                    % if all ascii characters after removing diacritics
                    if all(test_shortname < unicode_max) 
                        output.([search_params{found_i} '_short']) = test_shortname;
                    end

                end
            end
        end 
    end

    % Country specific formatting
    if ~isempty(output.country)
        switch output.country
            case 'United States'
                output.country = 'USA';
                output.country_short = 'US';
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

    % Water location
    if ~isempty(output.water)
        water_string = output.water;
        max_length = max_length - length(water_string) - 3;
    else
        water_string = '';
    end

    % Populate short names, if missing
    for param_i = 1:numel(search_params)
        if isempty(output.([search_params{param_i} '_short']))
            output.([search_params{param_i} '_short']) = output.(search_params{param_i});
        end
    end

    % Land location name
    acceptable = false;
    attempt = 0;
    max_attempts = 7;

    % attempt 1 - full locality, full admin1, full country
    % attempt 2 - full locality, short admin1, full country
    % attempt 3 - short locality, short admin1, full country
    % attempt 4 - full admin1, full country
    % attempt 5 - short admin1, full country
    % attempt 6 - full country
    % attempt 7 - short country

    while ~acceptable
        % Arbitrate parameters for formatted location
        formatstrings = cell(0); % empty cell array
        attempt = attempt + 1;

        if ~isempty(output.locality)
            if attempt <= 2
                formatstrings = [formatstrings {output.locality}];
            elseif attempt <= 3 % do not include after 4 attempts
                formatstrings = [formatstrings {output.locality_short}];
            end            
        end
        if ~isempty(output.administrative_area_level_1)
            if attempt == 1 || attempt == 4
                formatstrings = [formatstrings {output.administrative_area_level_1}];
            elseif attempt <= 5 % do not include after 5 attempts
                formatstrings = [formatstrings {output.administrative_area_level_1_short}];
            end
        end
        if ~isempty(output.country)
            if attempt <= 6
                formatstrings = [formatstrings {output.country}];
            else
                formatstrings = [formatstrings {output.country_short}];
            end
        end    

        % if the array is still empty, put something in it
        if isempty(formatstrings)
            formatstrings = [formatstrings {output.formatted}];
        end

        % Join strings with comma delimiter
        formatjoined = join(formatstrings,',');
        land_string = shorten_name(formatjoined{1});

        if length(land_string) <= max_length || attempt >= max_attempts
            acceptable = true;        
        end
    end

    % Output parameters
    locality = output.locality;
    state = output.administrative_area_level_1;
    country = output.country;

    % Check for undetected water
    if elevation_out <=0 && isempty(water_string) &&...
            isempty(output.locality) &&...
            isempty(output.administrative_area_level_1) &&...
            isempty(output.administrative_area_level_2) &&...
            isempty(output.administrative_area_level_3)
        water_string = 'water';
    end


    % Arbitrate location name
    % example - Pacific Ocean
    if isempty(land_string) && ~isempty(water_string)
        location_string = water_string;

    % example - Suances, Cantabria, Spain
    elseif isempty(water_string) && ~isempty(land_string)
        location_string = land_string;

    % example - Atlantic Ocean near France
    elseif ~isempty(water_string) && ~isempty(land_string)
        location_string = [water_string ' (' land_string ')'];
    else
        if elevation_out <= 0
            location_string = 'water';
        else
            location_string = 'unknown';
        end
    end
end

% Test output display
% output

end

function [new_name] = shorten_name(old_name)
% Shorten long names by removing common district names
% preserve order and apply more specific replacements first

    old_name = regexprep(old_name, 'Turkiye', 'Turkey');
    old_name = regexprep(old_name, 'Bosnia and Herzegovina', 'Bosnia');
    old_name = regexprep(old_name, 'Falkland Islands \(Islas Malvinas\)', 'Falkland Islands');
    old_name = regexprep(old_name, 'French Southern and Antarctic Lands', 'French Southern Lands');    
    old_name = regexprep(old_name, ' Xin Jiang Wei Wu Er Zi Zhi Qu', 'Xinjiang'); % preserve order
    old_name = regexprep(old_name, ' Zi Zhi Qu', ''); % preserve order
    old_name = regexprep(old_name, ' Zi Zhi Zhou', ''); % preserve order
    old_name = regexprep(old_name, 'Haixi Mongol and Tibetan Autonomous Prefecture', 'Qaidam'); % preserve order
    old_name = regexprep(old_name, ' Autonomous Prefecture', ''); % preserve orde
    old_name = regexprep(old_name, 'Districts of Republican Subordination', 'Karotegin'); % preserve order
    old_name = regexprep(old_name, ' Autonomous Region', '');
    old_name = regexprep(old_name, ' Autonomous Province', '');
    old_name = regexprep(old_name, ' Autonomous Okrug', '');
    old_name = regexprep(old_name, 'Air Force Base', 'AFB');
    old_name = regexprep(old_name, 'State of ', '');
    old_name = regexprep(old_name, 'Republic of ', '');
    old_name = regexprep(old_name, 'Republika ', '');
    old_name = regexprep(old_name, 'Region de ', '');
    old_name = regexprep(old_name, ' District', '');
    old_name = regexprep(old_name, ' Division', '');
    old_name = regexprep(old_name, ' Prefecture', '');
    old_name = regexprep(old_name, ' Region', '');
    old_name = regexprep(old_name, ' Republic', '');
    old_name = regexprep(old_name, ' County', '');
    old_name = regexprep(old_name, ' Oblast', '');
    old_name = regexprep(old_name, ' Province', '');
    old_name = regexprep(old_name, ' Governorate', '');
    old_name = regexprep(old_name, ' Voivodeship', '');
    old_name = regexprep(old_name, ' Municipality', ''); 
    new_name = old_name;
end
