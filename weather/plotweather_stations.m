% PLOTWEATHER_STATIONS

% Create figure and geoaxes
station_fig = figure;
set(station_fig, 'WindowState', 'maximized');
gx = geoaxes;
hold on

% Plot Weather Stations
geoscatter(EventData_IGRA_Nearby.LAT, EventData_IGRA_Nearby.LONG,'filled','b')
text(EventData_IGRA_Nearby.LAT, EventData_IGRA_Nearby.LONG, EventData_IGRA_Nearby.StationID)

% Plot trajectory
geoplot(EventData_latitudes,EventData_longitudes,'k','LineWidth',4)

% Plot reference point
geoscatter(nom_lat,nom_long,'filled','r')
