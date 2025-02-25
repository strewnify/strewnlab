function station_elev_summary = binAndSummarize(observations)

    % Define a minimum probability to consider a station
    % If the max 
    P_min = 0.02; 

    VCPmodes = unique(observations.sensorMode);
    all_elevations = []; % Initialize an empty array to store all elevations

    for mode_i = 1:numel(VCPmodes)
        mode = VCPmodes{mode_i};
        sample_elevation = getNEXRAD('elevations', mode);
        validIdx = getNEXRAD('reflectivity', mode);
        sample_elevation = sample_elevation(validIdx);

        all_elevations = [all_elevations sample_elevation]; % Append to the array
    end

    % Get the unique elevations to form the superset (remove duplicates)
    all_elevations = unique(all_elevations);
    all_elevations = sort(all_elevations);

    % Define bin edges using radar beamwidth and margin
    margin = getNEXRAD('beamwidth_deg') / 2;
    binEdges = [-inf (all_elevations(1:end-1) + all_elevations(2:end)) / 2 inf];  % Midpoints between consecutive values
     
    % Assign each observed_ELEV to a bin index
    observations.binIdx = discretize(observations.observed_ELEV, binEdges);
    observations.binIdx = all_elevations(observations.binIdx)';

%     % Calculate overall station stats
%     station_summary = groupsummary(observations,{'StationID'},'mean','P_detect');
%     station_summary = sortrows(station_summary,'mean_P_detect','descend');
    
    station_elev_summary = groupsummary(observations,{'StationID' 'binIdx'},'mean','P_detect');
    
%     % Sort by overall station performance
%     station_elev_summary = sortrows(station_elev_summary, 'StationID');
    
    station_elev_summary.StationID = categorical(station_elev_summary.StationID);
    
    uniqueStations = unique(station_elev_summary.StationID, 'stable'); 
    uniqueBins = unique(station_elev_summary.binIdx, 'sorted'); 
    categoricalBins = categorical(uniqueBins, uniqueBins, 'Ordinal', true);

    numStations = numel(uniqueStations);
    numCols = 3; % Number of columns in subplot grid
    numRows = ceil(numStations / numCols); % Rows needed

    % Find global y-axis limits
    yMax = max(station_elev_summary.mean_P_detect)*1.1;

    figure;
    for i = 1:numStations
        subplot(numRows, numCols, i);

        % Extract data for the current station
        stationData = station_elev_summary(station_elev_summary.StationID == uniqueStations(i), :);

        % Ensure all elevation bins are present (fill missing with NaN)
        meanP_detect_filled = nan(size(uniqueBins));
        [~, binLocs] = ismember(stationData.binIdx, uniqueBins);
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



