function result = islong(longitude)
% VALID = ISLAT(LATITUDE) Check for valid latitude
% Returns a boolean array indicating whether each element is within the valid range
    result = arrayfun(@(x) isnumeric(x) && isscalar(x) && (x >= -180) && (x <= 180), longitude);
end
