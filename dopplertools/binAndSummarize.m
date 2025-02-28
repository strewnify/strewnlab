function [fig_radarheatmap, station_summary] = binAndSummarize(observations)

    
    % Remove zero probability observations
    observations(observations.P_detect == 0,:)=[];
    
    % Round time values to the nearest second to avoid bin errors
     observations.ObservationTime = dateshift(observations.ObservationTime, 'start', 'second', 'nearest');
    
    % Create a list of unique radar station VCP modes
    VCPmodes = unique(observations.sensorMode);

    % Get radar scan data for all modes in this dataset
    all_elevations = []; % Initialize an empty array to store all elevations
    sum_scantime_s = 0;
    num_modes = numel(VCPmodes);
    for mode_i = 1:num_modes
        mode = VCPmodes(mode_i);
        sample_elevation = getNEXRAD('elevations', mode);
        validIdx = getNEXRAD('reflectivity', mode);
        sample_elevation = sample_elevation(validIdx);

        all_elevations = [all_elevations sample_elevation]; % Append to the array
        
        sum_scantime_s = sum_scantime_s + getNEXRAD('vcp_duration_s',mode);
    end
    
    % Calculate average scan time
    avg_scantime_s = sum_scantime_s/num_modes;
    scan_duration = seconds(avg_scantime_s);
           
    % Get the unique elevations to form the superset (remove duplicates)
    all_elevations = unique(all_elevations);
    all_elevations = sort(all_elevations);
    
    % Analyze Elevations
    % Define elevation bin edges 
    ELEV_binEdges = [-inf (all_elevations(1:end-1) + all_elevations(2:end)) / 2 inf];  % Midpoints between consecutive values
     
    % Assign each observed_ELEV to a bin index
    observations.ELEV_bin_idx = discretize(observations.observed_ELEV, ELEV_binEdges);
    observations.ELEV_bin = all_elevations(observations.ELEV_bin_idx)';

    % Analyse Time
    % Calculate time bins, considering event duration and scan duration
    datetime_min = min(observations.ObservationTime);
    datetime_max = max(observations.ObservationTime);
    event_duration = datetime_max - datetime_min;
    
    timestep = event_duration/ceil(2*event_duration/scan_duration);
    datetime_binEdges = min(observations.ObservationTime):timestep:max(observations.ObservationTime);
        
    % Calculate bin labels from bin centers
    datetime_binCenters = datetime_binEdges(1:end-1) + diff(datetime_binEdges)/2;
    numBins = length(datetime_binCenters); % Number of bins
    binLabels = cell(numBins, 1); % Pre-allocate cell array
    for i = 1:numBins
        binLabels{i} = datestr(datetime_binCenters(i), 'HH:MM:SS'); % Format datetime
    end
    datetime_binLabels = categorical(binLabels); % Convert to categorical
    
    % Assign bins and labels in the observations table
    observations.datetime_bin_idx = discretize(observations.ObservationTime, datetime_binEdges);
    observations.datetime_bin = datetime_binLabels(observations.datetime_bin_idx);

    % Calculate overall station stats
    station_summary = groupsummary(observations,{'StationID'},{'mean' 'max'},'P_detect');
    station_summary = sortrows(station_summary,'mean_P_detect','descend');
    
    % Summarize data by Elevation
    elev_summary = groupsummary(observations,{'StationID' 'ELEV_bin'},'mean','P_detect');

    % Summarize data by Time
    time_summary = groupsummary(observations,{'StationID' 'datetime_bin'},'mean','P_detect');

    % Sort by overall station performance
    elev_summary = sortrows(elev_summary, 'StationID');

    elev_summary.StationID = categorical(elev_summary.StationID);
    
    uniqueStations = categorical(station_summary.StationID);
    uniqueBins = unique(elev_summary.ELEV_bin, 'sorted'); 
    categoricalBins = categorical(uniqueBins, uniqueBins, 'Ordinal', true);

    numStations = numel(uniqueStations);
    numCols = 3; % Number of columns in subplot grid
    numRows = ceil(numStations / numCols); % Rows needed

    % Find global y-axis limits
    yMax = max(elev_summary.mean_P_detect)*1.1;

    % Plot Elevation bins for each Station
    figure;
    for i = 1:numStations
        subplot(numRows, numCols, i);

        % Extract data for the current station
        stationData = elev_summary(elev_summary.StationID == uniqueStations(i), :);

        % Ensure all elevation bins are present (fill missing with NaN)
        meanP_detect_filled = nan(size(uniqueBins));
        [~, binLocs] = ismember(stationData.ELEV_bin, uniqueBins);
        meanP_detect_filled(binLocs) = stationData.mean_P_detect;

        % Bar chart with uniform color
        bar(categoricalBins, meanP_detect_filled, 'FaceColor', [0.3 0.6 0.9]); % Light blue

        % Formatting
        title(char(uniqueStations(i)), 'Interpreter', 'none');
        xlabel('Elevation');
        ylabel('Mean P_{detect}');
        ylim([0 yMax]); % Set consistent y-axis limits
        grid on;
    end

    sgtitle('Mean Detection Probability by Station, Elevation, and Time'); % Overall title

 % Plot Time bins for each Station
    figure;
    for i = 1:numStations
        subplot(numRows, numCols, i);

        % Extract data for the current station
        stationData = time_summary(time_summary.StationID == uniqueStations(i), :);

        % Ensure all datetime bins are present (fill missing with NaN)
        meanP_detect_filled = nan(size(datetime_binLabels));
        [~, binLocs] = ismember(stationData.datetime_bin, datetime_binLabels);
        meanP_detect_filled(binLocs) = stationData.mean_P_detect;

        % Bar chart with uniform color
        bar(datetime_binLabels, meanP_detect_filled, 'FaceColor', [0.3 0.6 0.9]); % Light blue % Corrected bar axis

        % Formatting
        title(char(uniqueStations(i)), 'Interpreter', 'none');
        xlabel('Time HH:MM:SS UTC');
        ylabel('Mean P_{detect}');
        ylim([0 yMax]); % Set consistent y-axis limits
        grid on;
    end

    sgtitle('Mean Detection Probability by Station, Elevation, and Time'); % Overall title


fig_radarheatmap = figure;

% Create a dummy heatmap to get the colormap and limits
allAggregatedData = [];
for i = 1:numStations
    stationObservations = observations(observations.StationID == uniqueStations(i), :);
    if ~isempty(stationObservations)
        aggregatedData = groupsummary(stationObservations, {'datetime_bin', 'ELEV_bin'}, 'mean', 'P_detect');
        allAggregatedData = [allAggregatedData; aggregatedData]; % Combine data for overall limits
    end
end

if ~isempty(allAggregatedData)
    dummyHeatmap = heatmap(allAggregatedData, 'datetime_bin', 'ELEV_bin', 'ColorVariable', 'mean_P_detect');
    caxis_limits = caxis; % Get the colormap limits
    colormap(dummyHeatmap.Colormap); % Get the colormap
    delete(dummyHeatmap); % Delete the dummy heatmap
else
    caxis_limits = [0 1]; % Default values if no data exists
    colormap(parula);
end

for i = 1:numStations
    subplot(numRows, numCols, i);

    % Filter observations for the current station
    stationObservations = observations(observations.StationID == uniqueStations(i), :);

    % Pre-aggregate data using groupsummary
    if ~isempty(stationObservations)
        aggregatedData = groupsummary(stationObservations, {'datetime_bin', 'ELEV_bin'}, 'mean', 'P_detect');

        % Create heatmap from aggregated data
        h = heatmap(aggregatedData, 'datetime_bin', 'ELEV_bin', 'ColorVariable', 'mean_P_detect');
        h.MissingDataLabel = 'No Chance'; % Change the legend label
        h.Title = char(uniqueStations(i)); % Set title using the HeatmapChart object
        caxis(caxis_limits); % Set the same colormap limits for all heatmaps
        colormap(gca, colormap); % Set the same colormap for all heatmaps
        
        % Fix: Reverse the Y-axis order so higher elevations are on top
        h.YDisplayData = flipud(h.YDisplayData);
    else
        % Handle the case where there are no observations for a station
        text(0.5, 0.5, 'No data for this station', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
        title(char(uniqueStations(i)), 'Interpreter', 'none'); % This will still work for the text case.
    end

    % Formatting
    xlabel('Time HH:MM:SS UTC');
    ylabel('Elevation Sweep');
end


% Create and position the colorbar using gca
colorbar('Location', 'eastoutside'); % Use gca to get the current axes.
sgtitle(['Radar Detection Probability Heatmaps' newline datestr(datetime_min, 'YYYY-mmm-dd HH:MM:SS') ' ----> ' datestr(datetime_max, 'YYYY-mmm-dd HH:MM:SS') ' (UTC)'] , 'FontSize', 14, 'FontWeight', 'bold');

    
    % Output the table of filtered and analyzed data
    observation_analysis = observations;


