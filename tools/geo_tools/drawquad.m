function drawquad(eventfolder, lat, long, method, lat_error, long_error)
% Draw a rectangle around a truncated or rounded lat/lon point and writes to KML
% 
% Inputs:
%   lat      - Integer latitude (rounded value, truncated)
%   lon      - Integer longitude (rounded value, truncated)
%   filename - Name of the KML file to save the polygon
%
% The function assumes the precise coordinates were truncated, so it creates
% a rectangle encompassing the possible range of coordinates.
%
% For example, CNEOS coordinates are truncated to a precision of 0.1
% degrees, so it is useful to viusualize the possible area where the
% exact coordinates lie.
%
% See also: TESTQUADRANGLE, COUNTPRECISION.

    % Assume the lat and long values have the same precision
    % Example: 40.1, -80 would have a 0.1 precision
    precision = max(countprecision(lat),countprecision(long));

    % Arbitrate method
    switch method
        case 'rounded'
            % Coordinates were rounded to nearest precision,
            % so the true value lies within ±0.5 * precision
            half_precision = (10^-precision) / 2;
            minlat = lat - half_precision;
            maxlat = lat + half_precision;
            minlong = long - half_precision;
            maxlong = long + half_precision;
            
        case 'truncated'

            % Define the corners of the rectangle based on truncation
            % Coordinates were truncated (toward zero),
            % so the true value lies between [coordinate] and [coordinate + precision]            
            if lat < 0
                minlat = lat - 10^-precision;
                maxlat = lat;
            else
                minlat = lat;
                maxlat = lat + 10^-precision;
            end

            if long < 0
                minlong = long - 10^-precision;
                maxlong = long;
            else
                minlong = long;
                maxlong = long + 10^-precision;
            end
        case 'specific'
            minlat = lat - lat_error;
            maxlat = lat + lat_error;
            minlong = long - long_error;
            maxlong = long + long_error;
        otherwise
            error('method not supported')
    end
    
    % Display the bounding rectangle coordinates
    fprintf('Bounding rectangle:\n');
    fprintf('  minlat = %g\n  maxlat = %g\n  minlong = %g\n  maxlong = %g\n', minlat, maxlat, minlong, maxlong);
    
    % Write the polygon
    testquadrangle(eventfolder,minlat,maxlat,minlong,maxlong,true)

