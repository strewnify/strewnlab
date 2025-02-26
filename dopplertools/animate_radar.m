ELEV = 3.5;
window_s = 2;

minELEV = ELEV - getNEXRAD('beamwidth_deg')/2;
maxELEV = ELEV + getNEXRAD('beamwidth_deg')/2;

for simtime_s = 60:window_s:600
    
    idx = valid_observations & ...
          observations.SimulationTime > simtime_s - (window_s/2) & ...
          observations.SimulationTime < simtime_s + (window_s/2) & ...
          categorical(observations.StationID) == station & ...
          observations.P_detect > P_min & ...
          observations.observed_ELEV >= minELEV & observations.observed_ELEV <= maxELEV;
    
    DisplayTime = entrytime + seconds(simtime_s);

    % Convert DisplayTime to a formatted string (e.g., HH:MM:SS)
    DisplayTimeStr = datestr(DisplayTime, 'YYYY-mmm-dd HH:MM:SS UTC');
    
    ELEV_min = min(observations.observed_ELEV(idx));
    ELEV_max = max(observations.observed_ELEV(idx));

    scatter3(observations.Lat(idx), -observations.Long(idx), observations.Alt_km(idx), ...
             observations.Diameter_m(idx) .* 1000, observations.Mass_kg(idx) .* 1000, 'filled');
    
    zlim([0 10])    
    axis([42.4 42.5 83.7 83.9])

    % Big title
    bigTitle = (['Hamburg Radar Simulation | ' station ' | ' sprintf('ELEV = %.1f',ELEV)]);

    % Small subtitle with ELEV, DisplayTime, and SimTime
     datetimeTitle = sprintf('%s', DisplayTimeStr);
     timeTitle = sprintf('SimTime = %.2f s', simtime_s);

    % Display both titles
    title([bigTitle newline datetimeTitle newline timeTitle], 'FontSize', 14);

    drawnow
end
