function [fig_radarheatmap, station_summary] = binAndSummarize2(observations, station_data)


    % Remove low probability observations
    observations(observations.P_detect == 0, :) = [];

    % Round time values to the nearest second to avoid bin errors
    observations.ObservationTime = dateshift(observations.ObservationTime, 'start', 'second', 'nearest');

    % Calculate overall station stats
    station_summary = groupsummary(observations, {'StationID'}, {'mean', 'max'}, 'P_detect');
    station_summary = sortrows(station_summary, 'mean_P_detect', 'descend');

    numStations = length(station_data);
    numCols = 4; % Number of columns in subplot grid
    numRows = ceil(numStations / numCols); % Rows needed

    fig_radarheatmap = figure;

    % Calculate global min and max P_detect
    all_P_detect = [];
    for station_i = 1:numStations
        stationID = station_data(station_i).StationID;
        stationObservations = observations(strcmp(observations.StationID, stationID), :);
        if ~isempty(stationObservations)
            datetime_binEdges = station_data(station_i).Timestamps;
            elevBinEdges = station_data(station_i).elev_binEdges;
            stationObservations.datetime_bin_idx = discretize(stationObservations.ObservationTime, datetime_binEdges);
            stationObservations.ELEV_bin_idx = discretize(stationObservations.observed_ELEV, elevBinEdges);
            aggregatedData = groupsummary(stationObservations, {'datetime_bin_idx', 'ELEV_bin_idx'}, 'mean', 'P_detect');
            all_P_detect = [all_P_detect; aggregatedData.mean_P_detect];
        end
    end

    global_min_P_detect = 0;
    global_max_P_detect = min([max(all_P_detect), 1]);

    % Heatmaps for each Station
    for station_i = 1:numStations
        subplot(numRows, numCols, station_i);
        stationID = station_data(station_i).StationID;
        stationObservations = observations(strcmp(observations.StationID, stationID), :);

        if ~isempty(stationObservations)
            % Get bins from station_data
            datetime_binLabels = station_data(station_i).datetime_binLabels;
            datetime_binEdges = station_data(station_i).Timestamps;
            stationObservations.datetime_bin_idx = discretize(stationObservations.ObservationTime, datetime_binEdges);
            stationObservations.datetime_bin = datetime_binLabels(stationObservations.datetime_bin_idx);

            elevBinEdges = station_data(station_i).elev_binEdges;
            stationObservations.ELEV_bin_idx = discretize(stationObservations.observed_ELEV, elevBinEdges);
            stationObservations.ELEV_bin = station_data(station_i).elev_binLabels(stationObservations.ELEV_bin_idx)';

            aggregatedData = groupsummary(stationObservations, {'datetime_bin', 'ELEV_bin'}, 'mean', 'P_detect');

            h = heatmap(aggregatedData, 'datetime_bin', 'ELEV_bin', 'ColorVariable', 'mean_P_detect');
            h.MissingDataLabel = 'No Chance';
            h.Title = char(stationID);
            h.YDisplayData = flipud(h.YDisplayData);
            caxis([global_min_P_detect, global_max_P_detect]); % Use global limits
            colormap(gca, parula);
            h.CellLabelFormat = '%.3f';
        else
            text(0.5, 0.5, 'No data for this station', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
            title(char(stationID), 'Interpreter', 'none');
        end

        ylabel('Elevation Sweep');
    end

    colorbar('Location', 'eastoutside');
    sgtitle(['Radar Detection Probability Heatmaps' newline datestr(min(observations.ObservationTime), 'YYYY-mmm-dd HH:MM:SS') ' ----> ' datestr(max(observations.ObservationTime), 'YYYY-mmm-dd HH:MM:SS') ' (UTC)'], 'FontSize', 14, 'FontWeight', 'bold');
