function [poly_lats poly_lons] = inputsearched(center_lat,center_lon)

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

% Prompt user to select polygon
title('Select a single polygon.  Press RETURN key when complete.')
poly_lats = [];
poly_lons = [];
ax2 = axes; % create cartesian axes
hold on
ax2.Visible = 'off'; 
ax2.XTick = []; 
ax2.YTick = []; 
        
while 1==1
    
    [latitudeLimits,longitudeLimits] = geolimits(gx); % get actual limits after aspect adjustment by geolimits
    
     w = waitforbuttonpress
     current_char = double(get(map_handle,'CurrentCharacter'));
     if current_char == 13
         break
     end
     if w == 0     %0 for mouse click, 1 for button press
         delete(findobj('type', 'patch'));
         clear ax2
         geoaxes(gx) % select the geographic axes    
         cp = get(gca,'CurrentPoint');
         poly_lats(end+1) = cp(1,1);
         poly_lons(end+1) = cp(1,2);
%          [poly_lats(end+1),poly_lons(end+1)] = ginput(1)
      end
    
    if numel(poly_lats) > 2
        delete(findobj('type', 'patch'));
        
        
        ax2 = axes; % create cartesian axes
        ax2.XLim = longitudeLimits
        ax2.YLim = latitudeLimits
        ax2.Visible = 'off' 
        ax2.XTick = [] 
        ax2.YTick = []
        patch(ax2,poly_lons, poly_lats,'red','FaceAlpha',.4) % Modify patch color and transparency         
    end
end
close(map_handle)
