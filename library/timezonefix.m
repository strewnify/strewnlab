function [offset] = timezonefix(longitude)
%TIMEZONEFIX Allow NaN input to MATLAB's built-in TIMEZONE function.
%Default missing longitude values in array to 0 (UTC).

% Default to UTC for missing locations
longitude(isnan(longitude)) = 0;
    
offset = timezone(longitude);


