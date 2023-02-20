% GRAPHBALLOONS Use loaded weather data to graph balloon flight paths.

% Load event data
if exist('weatherdatamissing','var') && weatherdatamissing
    error('Balloon flight data unavailable.  Please load some weather data!')
end

if EventData_elapsedtimemissing
    warning('Some weather stations are missing elapsed time data, so flight path cannot be accurately determined.  For these stations, the flight path will appear vertical.')
end

% Sort data
EventData_ProcessedIGRA = sortrows(EventData_ProcessedIGRA,'HEIGHT');
EventData_ProcessedIGRA = sortrows(EventData_ProcessedIGRA,'HOUR');
EventData_ProcessedIGRA = sortrows(EventData_ProcessedIGRA,'DAY');
EventData_ProcessedIGRA = sortrows(EventData_ProcessedIGRA,'MONTH');
EventData_ProcessedIGRA = sortrows(EventData_ProcessedIGRA,'YEAR');
EventData_ProcessedIGRA = sortrows(EventData_ProcessedIGRA,'DatasetIndex'); 

% Graph balloon flight
balloons_fig = figure;
hold on
grid on
view(3)
axis([-inf inf -inf inf 0 round(max(EventData_ProcessedIGRA.HEIGHT),-3)+1000])
daspect([1/long_metersperdeg 1/lat_metersperdeg 1]);
set(1,'Position',[100,90,1200,900])
plot3(nom_long,nom_lat,geometric_elevation,'bx','MarkerSize',ref_marksize)
plot3([startlocation(2) endlocation(2)],[startlocation(1) endlocation(1)],[startposition(3), endposition(3)])
title([SimulationName ': Radiosonde Weather Balloon Flight Paths'])
xlabel('Longitude');
ylabel('Latitude');
zlabel('Altitude, meters');

IGRA_numDatasets = max(EventData_ProcessedIGRA.DatasetIndex);

% Graph results as animation
for dataset = 1:IGRA_numDatasets
    % Resample to speed animation
    balloonspeed = 1;
    filter = find(EventData_ProcessedIGRA.DatasetIndex == dataset);
    resample = repmat([true;false(balloonspeed-1,1)],floor(size(filter,1)/balloonspeed),1);
    filter = filter(resample);
    comet3(EventData_ProcessedIGRA.LONG(filter),EventData_ProcessedIGRA.LAT(filter),EventData_ProcessedIGRA.HEIGHT(filter));
end 
