function [lats lons] = inputpoints(center_lat,center_lon)

earth = referenceEllipsoid('earth','km');
radius_km = 3;

% Calculate map limits from radius
nw_corner = reckon(center_lat,center_lon,radius_km./2,315,earth); 
se_corner = reckon(center_lat,center_lon,radius_km./2,135,earth);
lat_range = [se_corner(1,1) nw_corner(1,1)];
lon_range = [nw_corner(1,2) se_corner(1,2)];

% Create a figure and maximize it
gx = geoaxes('Basemap','satellite');
map_handle = gcf;
map_handle.WindowState = 'maximized';

% Set the limits to the map limits
geolimits(gx,lat_range,lon_range);

% Prompt user to select points
title('Select points.  Press RETURN key when complete.')
[lats,lons] = ginput();

close(map_handle)
