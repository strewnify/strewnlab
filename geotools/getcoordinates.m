function [ LAT, LONG ] = getcoordinates(locality)
% [LAT, LONG] = GETCOORDINATES( ADDRESS )     Query Google Maps
% geocoding service to determine the coodinates of a locality.
% Google charges $5 per 1000 requests, so please do not abuse this function.

% load Google Maps API
strewnconfig

% Default values
LAT = NaN;
LONG = NaN;

try
    response_raw = webread(['https://maps.googleapis.com/maps/api/geocode/json?address=' strrep(locality,' ','+') '&key=' GoogleMapsAPIkey]);    
catch
    logformat(['Google Maps geocoding failed for ' locality ', manual geocoding required.'],'WARN')
end

switch response_raw.status
    case 'OK'
        if numel(response_raw.results) == 1
            LAT = response_raw.results.geometry.location.lat;
            LONG = response_raw.results.geometry.location.lng;
        else
            logformat(['Google Maps geocoding search for ''' locality ''' returned multiple results.'],'DEBUG')
        end
    otherwise
        logformat(['Google Maps geocoding search for ''' locality ''' returned status: ' response_raw.status],'DEBUG')
end
