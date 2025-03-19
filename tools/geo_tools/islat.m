function result = islat(latitude)
% VALID = ISLAT(LATITUDE) Check for valid latitude
% Returns a boolean array indicating whether each element is within the valid range
    result = arrayfun(@(x) isnumeric(x) && isscalar(x) && (x >= -90) && (x <= 90), latitude);
end
