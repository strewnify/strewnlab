function probability_report = generateSweepReport(observations, EventData_station_metadata)
    % Initialize a cell array for the report rows
    report_data = {};
    row_idx = 1;

    numStations = length(EventData_station_metadata);

    for station_i = 1:numStations
        stationID = EventData_station_metadata(station_i).StationID;
        stationObs = observations(strcmp(observations.StationID, stationID), :);

        if ~isempty(stationObs)
            % Define bins based on metadata
            timeEdges = EventData_station_metadata(station_i).Timestamps;
            timeLabels = EventData_station_metadata(station_i).datetime_binLabels;
            elevEdges = EventData_station_metadata(station_i).elev_binEdges;
            elevLabels = EventData_station_metadata(station_i).elev_binLabels;

            % Assign observations to bins
            stationObs.time_idx = discretize(stationObs.ObservationTime, timeEdges);
            stationObs.elev_idx = discretize(stationObs.observed_ELEV, elevEdges);

            % Aggregate data to find non-empty sweeps
            summary = groupsummary(stationObs, {'time_idx', 'elev_idx'}, 'mean', 'P_detect');

            for i = 1:height(summary)
                t_idx = summary.time_idx(i);
                e_idx = summary.elev_idx(i);
                
                if ~isnan(t_idx) && ~isnan(e_idx)
                    report_data{row_idx, 1} = char(stationID);
                    report_data{row_idx, 2} = char(timeLabels(t_idx));
                    report_data{row_idx, 3} = char(elevLabels(e_idx));
                    report_data{row_idx, 4} = summary.mean_P_detect(i);
                    row_idx = row_idx + 1;
                end
            end
        end
    end

    % Convert to a Table
    probability_report = cell2table(report_data, ...
        'VariableNames', {'Station', 'Time_UTC', 'Elevation_Sweep', 'Avg_P_detect'});
    
    probability_report.Avg_P_detect = round(probability_report.Avg_P_detect, 4);
    
end