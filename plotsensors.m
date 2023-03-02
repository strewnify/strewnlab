function plotsensors(data)

% Colors
colors = 'brgbmk';
color_idx = 1;

% Define earth ellipsoid
earth = referenceEllipsoid('earth','km');

% Open axes
geoaxes
hold on
geolimits([-90 90],[-360 360])

% Plot cameras
numcams = size(data,1);

for idx = 1:numcams
    switch data.Type
        case "AllSky"
            geoplot_sensor(data.LAT(idx),data.LONG(idx),data.range_km(idx),[],earth,data.StationID(idx),colors(color_idx))            
        case "Camera"
            geoplot_sensor(data.LAT(idx),data.LONG(idx),data.range_km(idx),[wrapTo360(data.cam_AZ(idx)-data.cam_hor_FOV(idx)/2) wrapTo360(data.cam_AZ(idx)+data.cam_hor_FOV(idx)/2)],earth,data.StationID(idx),colors(color_idx))
        otherwise
            geoplot_sensor(data.LAT(idx),data.LONG(idx),data.range_km(idx),[],earth,data.StationID(idx),colors(color_idx))
    end
            
    color_idx = color_idx + 1;
    if color_idx > numel(colors)
        color_idx = 1;
    end
    
end