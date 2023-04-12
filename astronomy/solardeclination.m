function [declination] = solardeclination(day)
% [DECLINATION] = SOLARDECLINATION(DAY) Calculates solar declination, as a
% function of day of the year.
% Source: https://www.pveducation.org/pvcdrom/properties-of-sunlight/declination-angle

declination = -23.45 .* cosd((360/365) .* (day + 10));

end

