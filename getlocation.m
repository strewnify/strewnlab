function [ location ] = getlocation(latitude,longitude)
% LOCATION = GETLOCATION( LATITUDE, LONGITUDE )     Query Google Maps
% reverse geocoding service to determine the locality of a set of
% coordinates.  Google charges $5 per 1000 requests, so please do not abuse
% this function.

% load Google Maps API
strewnconfig

try
    location_raw = webread(['https://maps.googleapis.com/maps/api/geocode/json?latlng=' num2str(latitude) ',' num2str(longitude) '&key=' GoogleMapsAPIkey]);
catch
    error('Google Maps reverse geocoding failed, check internet connection and try again.')
end

try

    switch class(location_raw.results)
        case 'struct'
            numresults = size(location_raw.results,1);
            
            switch numresults
                case 1
                    location = location_raw.results.formatted_address;
                case 2
                    [location trash2] = location_raw.results.formatted_address;
                case 3
                    [trash1 location trash3] = location_raw.results.formatted_address;
                case 4
                    [trash1 trash2 location trash4] = location_raw.results.formatted_address;
                case 5
                    [trash1 trash2 location trash4 trash5] = location_raw.results.formatted_address;
                case 6
                    [trash1 trash2 location trash4 trash5 trash6] = location_raw.results.formatted_address;
                case 7
                    [trash1 trash2 location trash4 trash5 trash6 trash7] = location_raw.results.formatted_address;
                case 8
                    [trash1 trash2 trash3 location trash5 trash6 trash7 trash8] = location_raw.results.formatted_address;
                otherwise
                    [trash1 trash2 trash3 trash4 location trash6 trash7 trash8 trash9] = location_raw.results.formatted_address;
            end
        case 'cell'
            numresults = size(location_raw.results,1);
            switch numresults
                case 1
                    location = location_raw.results{1}.formatted_address;
                case 2
                    location = location_raw.results{1}.formatted_address;
                case 3
                    location = location_raw.results{2}.formatted_address;
                case 4
                    location = location_raw.results{3}.formatted_address;
                case 5
                    location = location_raw.results{3}.formatted_address;
                case 6
                    location = location_raw.results{3}.formatted_address;
                case 7
                    location = location_raw.results{3}.formatted_address;
                case 8
                    location = location_raw.results{4}.formatted_address;
                otherwise
                    location = location_raw.results{5}.formatted_address;
            end
        otherwise
            location = [ ' ' ];
    end
catch
    location = [ '' ];
end