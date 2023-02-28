% Plot your Geo data here
latSeattle = 47.62;
lonSeattle = -122.33;
latAnchorage = 61.20;
lonAnchorage = -149.9;
gx = geoaxes('Basemap','satellite');

 
% Plot your Patch data here
ax2 = axes;
x = [0.25 0.6 0.6 0.25]; % Modify x coordinates of the polygon 
y = [0.25 0.25 0.4 0.4]; % Modify y coordinates of the polygon
patch(ax2, x, y,'red','FaceAlpha',.4); % Modify patch color and transparency 
axis([0 1 0 1]);
% Set ax2 visibility to 'off'
ax2.Visible = 'off'; 
ax2.XTick = []; 
ax2.YTick = []; 
