% PLOTWEATHER

plot_numsize = 14;
plot_labelsize = 20;
plot_line_width = 2;

weather_max_height_km = round(max(EventData_ProcessedIGRA.HEIGHT_km),-1);
%weather_max_height_km = 5;

% Create a figure
handle_weather = figure;

% Sort data for output
EventData_ProcessedIGRA = sortrows(EventData_ProcessedIGRA,'HEIGHT');

% Plot wind speed
subplot(1,4,1)
hold on
grid on
title([SimulationName ': Wind Speed'],'FontSize',plot_labelsize)
xlabel('Wind Speed, m/s','FontSize',plot_labelsize);
ylabel('Altitude, km','FontSize',plot_labelsize);
axis([-inf inf 0 weather_max_height_km])
ax = gca;
ax.FontSize = plot_numsize;
plot(EventData_ProcessedIGRA.WSPD_MODEL, EventData_ProcessedIGRA.HEIGHT_km,'k','LineWidth',plot_line_width)
plot(EventData_ProcessedIGRA.WSPD_MIN, EventData_ProcessedIGRA.HEIGHT_km,'g')
plot(EventData_ProcessedIGRA.WSPD_MAX, EventData_ProcessedIGRA.HEIGHT_km,'r')
scatter(EventData_ProcessedIGRA.WSPD, EventData_ProcessedIGRA.HEIGHT_km, '.b') 
% fitobject = fit(elevations,wspd,'gauss2');
% plot(fitobject)

% Plot wind direction
subplot(1,4,2)
hold on
grid on
title([SimulationName ': Wind Direction'],'FontSize',plot_labelsize)
xlabel('Wind Direction (originates from)','FontSize',plot_labelsize);
ylabel('Altitude, km','FontSize',plot_labelsize);
axis([0 360 0 weather_max_height_km])
ax = gca;
ax.FontSize = plot_numsize;
ax.XTick = 0:90:360;
scatter(EventData_ProcessedIGRA.WDIR, EventData_ProcessedIGRA.HEIGHT_km,'.b') 
plot(EventData_ProcessedIGRA.WDIR_MODEL, EventData_ProcessedIGRA.HEIGHT_km,'k','LineWidth',plot_line_width)
plot(EventData_ProcessedIGRA.WDIR_MIN, EventData_ProcessedIGRA.HEIGHT_km,'g')
plot(EventData_ProcessedIGRA.WDIR_MAX, EventData_ProcessedIGRA.HEIGHT_km,'r')

% Plot pressure
subplot(1,4,3)
hold on
grid on
title([SimulationName ': Air Pressure'],'FontSize',plot_labelsize)
xlabel('Pressure, kPa','FontSize',plot_labelsize);
ylabel('Altitude, km','FontSize',plot_labelsize);
axis([0 105 0 weather_max_height_km])
ax = gca;
ax.FontSize = plot_numsize;
ax.XTick = 0:20:105;
scatter(EventData_ProcessedIGRA.PRESS, EventData_ProcessedIGRA.HEIGHT_km,'.b')
plot(EventData_pressure_Pa_2D_model./1000,EventData_altitudes_fine./1000,'k','LineWidth',plot_line_width)

% Plot temperature
subplot(1,4,4)
hold on
grid on
title([SimulationName ': Air Temperature'],'FontSize',plot_labelsize)
xlabel('Temperature, deg C','FontSize',plot_labelsize);
ylabel('Altitude, km','FontSize',plot_labelsize);
axis([-80 40 0 weather_max_height_km])
ax = gca;
ax.FontSize = plot_numsize;
ax.XTick = -200:20:200;
scatter(EventData_ProcessedIGRA.TEMP, EventData_ProcessedIGRA.HEIGHT_km,'.b')
plot(EventData_temp_2D_model,EventData_altitudes_fine./1000,'k','LineWidth',plot_line_width)

% Maximize plot
set(0,'units','pixels');
set(handle_weather, 'Position', get(0, 'Screensize').*[1 1 0.9 0.9])

% Save the current image to file
try
    nowtime = datetime('now','TimeZone','UTC');
    pngfilestring = [SimulationName '_WeatherSummary' SimVersionSfx '.png'];

    cd(exportfolder)
    saveas(gcf,pngfilestring);

    % return to main folder
    cd(getSession('folders','mainfolder'))
catch
    % return to main folder
    cd(getSession('folders','mainfolder'))    
    warning('Weather plot save failed.');
end