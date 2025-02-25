function summary = binAndSummarize(observations, VCPmode)

    % Define a minimum probability to consider a station
    % If the max 
    P_min = 0.02; 

	% Get elevation angles for the given VCP mode
    elevation = getNEXRAD('elevations', VCPmode);
    
    % Apply reflectivity filter (if applicable)
    validIdx = getNEXRAD('reflectivity', VCPmode); 
    elevation = elevation(validIdx);

    % Define bin edges using radar beamwidth and margin
    margin = getNEXRAD('beamwidth_deg') / 2;
    binEdges = [-inf (elevation(1:end-1) + elevation(2:end)) / 2 inf];  % Midpoints between consecutive values
     
    % Assign each observed_ELEV to a bin index
    observations.binIdx = discretize(observations.observed_ELEV, binEdges);
    observations.binIdx = elevation(observations.binIdx)';

    summary = groupsummary(observations,{'StationID' 'binIdx'},'mean','P_detect');

    summary.StationID = categorical(summary.StationID);
    
    uniqueStations = unique(summary.StationID, 'stable'); 
    uniqueBins = unique(summary.binIdx, 'sorted'); 
    categoricalBins = categorical(uniqueBins, uniqueBins, 'Ordinal', true);

    numStations = numel(uniqueStations);
    numCols = 3; % Number of columns in subplot grid
    numRows = ceil(numStations / numCols); % Rows needed

    % Find global y-axis limits
    yMax = max(summary.mean_P_detect)*1.1;

    figure;
    for i = 1:numStations
        subplot(numRows, numCols, i);

        % Extract data for the current station
        stationData = summary(summary.StationID == uniqueStations(i), :);

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



