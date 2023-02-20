function [ longitudes, latitudes ] = strewnzone(strewndata, minmass, maxmass, numpoints)
%STREWNZONE Filled area plot of strewn field.
%   STREWNZONE takes output from the APOCALYPSE projectile simulation
%   program and plots the strewn field as a shaded polygon.
%   Input sigmamult is the number of standard deviations to include

clear latitudes
clear longitudes
clear breakpoint
clear latdata
clear longdata
clear inrange_data

% preallocate vectors
latitudes = zeros(1,numpoints * 2);
breakpoint = zeros(1,numpoints);

% strewn data is structured with
% latitude at position 13
% longitude at position 12
indices = find(strewndata.mass > minmass & strewndata.mass < maxmass);
inrange_data = strewndata(indices,:);
MINLAT = min(inrange_data.Latitude);
MAXLAT = max(inrange_data.Latitude);
MINLONG = min(inrange_data.Longitude);
MAXLONG = max(inrange_data.Longitude);

% Create breakpoints
for i = 1:numpoints
    breakpoint(i) = MINLONG + (i-1) * ((MAXLONG - MINLONG)/(numpoints-1));
end

% Bin data
for i = 2:(numpoints-1)
    binindices = find(inrange_data.Longitude > breakpoint(i-1) & inrange_data.Longitude < breakpoint(i+1));   
    latitudes(i) = max(inrange_data.Latitude(binindices));
    latitudes(2*numpoints + 1 - i) = min(inrange_data.Latitude(binindices));
end

% Bin far left breakpoint
binindices = find(inrange_data.Longitude < breakpoint(2));
latitudes(1) = max(inrange_data.Latitude(binindices));
latitudes(2 * numpoints) = min(inrange_data.Latitude(binindices));

% Bin far right breakpoint
binindices = find(inrange_data.Longitude > breakpoint(numpoints - 1));
latitudes(numpoints) = max(inrange_data.Latitude(binindices));
latitudes(numpoints + 1) = min(inrange_data.Latitude(binindices));

% Populate breakpoint vector
longitudes = [breakpoint flip(breakpoint)];



