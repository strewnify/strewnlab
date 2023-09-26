function plotsensors(data)

% Define earth ellipsoid
earth = referenceEllipsoid('earth','km');

% Open axes
geoaxes
hold on
geolimits([-90 90],[-360 360])

% Plot cameras
numcams = size(data,1);



for idx = 1:numcams
    switch data.Type(idx)
        case "Camera"
            if isnan(data.sensorELEV) | data.sensorELEV == 90 % AllSky cam
                geoplot_sensor(data.LAT(idx),data.LONG(idx),data.range_km(idx),[],earth,data.StationID(idx),data.plot_color(idx,:))   
                
            else
                geoplot_sensor(data.LAT(idx),data.LONG(idx),data.range_km(idx),[wrapTo360(data.sensorAZ(idx)-data.sensor_hor_FOV(idx)/2) wrapTo360(data.sensorAZ(idx)+data.sensor_hor_FOV(idx)/2)],earth,data.StationID(idx),data.plot_color(idx,:))
            end
        otherwise
            geoplot_sensor(data.LAT(idx),data.LONG(idx),data.range_km(idx),[],earth,data.StationID(idx),data.plot_color(idx,:))
    end
end