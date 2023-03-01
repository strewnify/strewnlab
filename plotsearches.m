function plotsearches(search_data)
% PLOTSEARCHES

% count search polygons and get all points to set map limits
num_areas = size(search_data,2);
lats_all =[];
lons_all = [];
for area_idx = 1:num_areas
    lats_all = [lats_all search_data(area_idx).lat];
    lons_all = [lons_all search_data(area_idx).lon];
end

[lat,lon] = polyjoin({search_data(:).lat},{search_data(:).lon});
[latMerged, lonMerged] = polymerge(lat, lon);

% Set axes
[latlim,lonlim] = geoquadpt(lats_all,lons_all);
latlim(1) = latlim(1) - 0.05*(latlim(2) - latlim(1));
latlim(2) = latlim(2) + 0.05*(latlim(2) - latlim(1));
lonlim(1) = lonlim(1) - 0.05*(lonlim(2) - lonlim(1));
lonlim(2) = lonlim(2) + 0.05*(lonlim(2) - lonlim(1));

% Create a map
gx = geoaxes('Basemap','satellite')
[latitudeLimits,longitudeLimits] = geolimits(gx,latlim,lonlim)
title('All search areas shown / DO NOT ZOOM, not supported')

map_handle = gcf;
map_handle.WindowState = 'maximized';

% get limits again, because there is a bug in the maximize delay
pause(1)
[latitudeLimits,longitudeLimits] = geolimits(gx,latlim,lonlim)

earthradius = 6371000;
lat_metersperdeg = 2*earthradius*pi/360;
long_metersperdeg = 2*earthradius*pi*cos(deg2rad(latitudeLimits(1)))/360;

% show search polygons
ax2 = axes; % create cartesian axes
daspect([1/long_metersperdeg 1/lat_metersperdeg 1]);
ax2.XLim = longitudeLimits;
ax2.YLim = latitudeLimits;
ax2.Visible = 'off';
ax2.XTick = [];
ax2.YTick = [];


for area_idx = 1:num_areas
    if ~strcmp(search_data(area_idx).notes,'poor')
        patch(ax2,search_data(area_idx).lon, search_data(area_idx).lat,'white','FaceAlpha',0.2) % Modify patch color and transparency     
    end
end


