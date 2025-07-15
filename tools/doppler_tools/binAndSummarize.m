function [fig_radarheatmap, station_summary] = binAndSummarize(observations, EventData_station_metadata)

 % Remove low probability observations
    observations(observations.P_detect == 0, :) = [];

    % Round time values to the nearest second to avoid bin errors
    observations.ObservationTime = dateshift(observations.ObservationTime, 'start', 'second', 'nearest');

    % Calculate overall station stats
    station_summary = groupsummary(observations, {'StationID'}, {'mean', 'max'}, 'P_detect');
    station_summary = sortrows(station_summary, 'mean_P_detect', 'descend');

    numStations = length(EventData_station_metadata);
    numCols = 3; % Number of columns in subplot grid
    numRows = ceil(numStations / numCols); % Rows needed

    % Find global y-axis limits
    yMax = max(station_summary.max_P_detect) * 1.1;

%     % Plot Elevation bins for each Station
%     figure;
%     for station_i = 1:numStations
%         stationID = EventData_station_metadata(station_i).StationID;
% 
%         % Get observations for this station
%         stationObservations = observations(strcmp(observations.StationID, stationID), :);
% 
%         % Get elevation bins from EventData_station_metadata
%         stationObservations.ELEV_bin_idx = discretize(stationObservations.observed_ELEV, EventData_station_metadata(station_i).elev_binEdges);
%         stationObservations.ELEV_bin = EventData_station_metadata(station_i).elev_binLabels(stationObservations.ELEV_bin_idx)';
% 
%         elev_summary = groupsummary(stationObservations, {'ELEV_bin'}, 'mean', 'P_detect');
% 
%         % Select the correct subplot before plotting
%         subplot(numRows, numCols, station_i);
% 
%         % Bar chart
%         bar(elev_summary.ELEV_bin, elev_summary.mean_P_detect, 'FaceColor', [0.3 0.6 0.9]);
%         title(char(stationID), 'Interpreter', 'none');
%         xlabel('Elevation');
%         ylabel('Mean P_{detect}');
%         ylim([0 yMax]);
%         grid on;
%     end
%     sgtitle('Mean Detection Probability by Station and Elevation');
% 
% 
%     % Plot Time bins for each Station
%     figure;
%     for station_i = 1:numStations
%         stationID = EventData_station_metadata(station_i).StationID;
%         
%         % Get observations for this station
%         stationObservations = observations(strcmp(observations.StationID, stationID), :);
% 
%         % Get time bins from EventData_station_metadata
%         datetime_binLabels = EventData_station_metadata(station_i).datetime_binLabels;
%         datetime_binEdges = EventData_station_metadata(station_i).Timestamps;
%         stationObservations.datetime_bin_idx = discretize(stationObservations.ObservationTime, datetime_binEdges);
%         stationObservations.datetime_bin = datetime_binLabels(stationObservations.datetime_bin_idx);
% 
%         time_summary = groupsummary(stationObservations, {'datetime_bin'}, 'mean', 'P_detect');
% 
%         % Bar chart
%         bar(time_summary.datetime_bin, time_summary.mean_P_detect, 'FaceColor', [0.3 0.6 0.9]);
%         title(char(stationID), 'Interpreter', 'none');
%         xlabel('Time HH:MM:SS UTC');
%         ylabel('Mean P_{detect}');
%         ylim([0 yMax]);
%         grid on;
% 
%         if station_i < numStations
%             subplot(numRows, numCols, station_i + 1);
%         end
%     end
%     sgtitle('Mean Detection Probability by Station and Time');

    fig_radarheatmap = figure;

    % Heatmaps for each Station
    for station_i = 1:numStations
        subplot(numRows, numCols, station_i);
        stationID = EventData_station_metadata(station_i).StationID;
        
        % Get observations for this station
        stationObservations = observations(strcmp(observations.StationID, stationID), :); % Corrected line

        if ~isempty(stationObservations)
            % Get bins from EventData_station_metadata
            datetime_binLabels = EventData_station_metadata(station_i).datetime_binLabels;
            datetime_binEdges = EventData_station_metadata(station_i).Timestamps;
            stationObservations.datetime_bin_idx = discretize(stationObservations.ObservationTime, datetime_binEdges);
            stationObservations.datetime_bin = datetime_binLabels(stationObservations.datetime_bin_idx);

            elevBinEdges = EventData_station_metadata(station_i).elev_binEdges;
            stationObservations.ELEV_bin_idx = discretize(stationObservations.observed_ELEV, elevBinEdges);
            stationObservations.ELEV_bin = EventData_station_metadata(station_i).elev_binLabels(stationObservations.ELEV_bin_idx)';

            aggregatedData = groupsummary(stationObservations, {'datetime_bin', 'ELEV_bin'}, 'mean', 'P_detect');

            h = heatmap(aggregatedData, 'datetime_bin', 'ELEV_bin', 'ColorVariable', 'mean_P_detect');
            h.MissingDataLabel = 'No Chance';
            h.Title = char(stationID);
            h.YDisplayData = flipud(h.YDisplayData);
            caxis([min([aggregatedData.mean_P_detect; 0]), max([aggregatedData.mean_P_detect; 1])]);
            colormap(gca, parula);
        else
            text(0.5, 0.5, 'No data for this station', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
            title(char(stationID), 'Interpreter', 'none');
        end
        
        %xlabel('Time HH:MM:SS UTC');
        ylabel('Elevation Sweep');
        
        % Format cell labels to 3 decimal places
        h.CellLabelFormat = '%.3f'; 
    end
    
    colorbar('Location', 'eastoutside');
    sgtitle(['Radar Detection Probability Heatmaps' newline datestr(min(observations.ObservationTime), 'YYYY-mmm-dd HH:MM:SS') ' ----> ' datestr(max(observations.ObservationTime), 'YYYY-mmm-dd HH:MM:SS') ' (UTC)'], 'FontSize', 14, 'FontWeight', 'bold');

