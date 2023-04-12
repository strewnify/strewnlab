function [elevation] = solarelevation(LAT, LON, DateTime)
% [ELEVATION] = SOLARELEVATION(LAT, DAY) Calculates solar elevation, as a
% function of day of the year and latitude.
% Source: https://www.pveducation.org/pvcdrom/properties-of-sunlight/declination-angle

daynum = datenum(DateTime)-datenum(year(DateTime),1,1);
declination = solardeclination(daynum);
HRA = hourangle(LON,DateTime);

elevation = asind(sind(declination) .* sind(LAT) + cosd(declination) .* cosd(LAT) .* cosd(HRA));

end

