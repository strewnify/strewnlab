function [ location ] = getlocation_test(lat,lon)
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

water = char;
locality = char;
state = char;
admin1 = char;
admin2 = char;
admin3 = char;
admin4 = char;
country = char;
oldmethod = char;
location = char;

[body_of_water,elevation_out] = identifywater(lat,lon);   
if ~strcmp(body_of_water,'unknown') && ~strcmp(body_of_water,'depression')
    location = body_of_water{1};
    disp(['water - ' location])
end

try

    switch class(location_raw.results)
        case 'struct'
            
            location = location{1};
            if strcmp(location,'unknown')
                location = 'ocean';
            end
            disp(['struct - ' location])

        case 'cell'
            numresults = size(location_raw.results,1);
            
            % Look for country
            for res_idx = 1:numresults
                if any(matches(location_raw.results{res_idx}.types,'country'))
                    country = location_raw.results{res_idx}.formatted_address;                   
                end
            end   
            
            % Look for locality
            for res_idx = 1:numresults
                if any(matches(location_raw.results{res_idx}.types,'locality'))
                    locality = location_raw.results{res_idx}.formatted_address;                    
                end
            end
            
            % Look for administrative area level 1
            for res_idx = 1:numresults
                if any(matches(location_raw.results{res_idx}.types,'administrative_area_level_1'))
                    admin1 = location_raw.results{res_idx}.formatted_address;                    
%                     if strcmp(country,'United States')
                        state = location_raw.results{res_idx}.address_components(1).long_name;
%                     end
                end
            end
            
            % Look for administrative area level 2
            for res_idx = 1:numresults
                if any(matches(location_raw.results{res_idx}.types,'administrative_area_level_2'))
                    admin2 = location_raw.results{res_idx}.formatted_address;                    
                end
            end
            
            % Look for administrative area level 3
            for res_idx = 1:numresults
                if any(matches(location_raw.results{res_idx}.types,'administrative_area_level_3'))
                    admin3 = location_raw.results{res_idx}.formatted_address;                    
                end
            end
            
            % Look for administrative area level 4
            for res_idx = 1:numresults
                if any(matches(location_raw.results{res_idx}.types,'administrative_area_level_4'))
                    admin4 = location_raw.results{res_idx}.formatted_address;                    
                end
            end
            
             
            
            switch numresults
                case 1
                    oldmethod = location_raw.results{1}.formatted_address;
                    disp('case 1')
                case 2
                    oldmethod = location_raw.results{1}.formatted_address;
                    disp('case 2')
                case 3
                    oldmethod = location_raw.results{2}.formatted_address;
                    disp('case 3')
                case 4
                    oldmethod = location_raw.results{3}.formatted_address;
                    disp('case 4')
                case 5
                    oldmethod = location_raw.results{3}.formatted_address;
                    disp('case 5')
                case 6
                    oldmethod = location_raw.results{3}.formatted_address;
                    disp('case 6')
                case 7
                    oldmethod = location_raw.results{3}.formatted_address;
                    disp('case 7')
                case 8
                    oldmethod = location_raw.results{4}.formatted_address;
                    disp('case 8')
                otherwise
                    oldmethod = location_raw.results{5}.formatted_address;
                    disp('case otherwise')
            end            
        otherwise
            oldmethod = 'otherwise';
    end
catch
    oldmethod = 'catch';
end


if isempty(location)
    location = 'test';
end

% Country specific formatting
if ~isempty(country)
    switch country
        case 'United States'
            if ~isempty(locality)
               locality = regexprep(locality, '\d[0-9_]+\d', char(8));
            end
            
    end
else
    disp('NO COUNTRY FOUND!')
end

% Find shortest administrative region name
shortadmin = char;
adminlengths = [strlength(admin2) strlength(admin3) strlength(admin4)];
shortadmin_length = min(adminlengths(adminlengths>0));
if ~isempty(shortadmin_length)
    adminshortest = find(adminlengths == shortadmin_length,1);
    switch adminshortest
        case 1
            shortadmin = admin2;
        case 2
            shortadmin = admin3;
        case 3
            shortadmin = admin4;
    end
end

% Remove leading numbers
if isstrprop(location(1),'digit')
    locality = extractAfter(locality,find(isstrprop(locality,'alpha'),1,'first')-1);
end

locality
admin1
admin2
admin3
admin4
shortadmin
state
country
water
oldmethod