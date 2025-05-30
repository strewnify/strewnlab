function station_data = getstation_metadata(StationIDs,entrytime)
%GETSTATION_METADATA Retrieves and processes NEXRAD metadata for radar stations.
%
%   station_data = getstation_metadata(StationIDs, entrytime) retrieves VCP mode metadata
%   from NOAA NEXRAD servers for given stations and time. Handles multi-day data,
%   missing data (user prompts), and calculates time/elevation bins.
%
%   Inputs:
%       StationIDs - Cell array of radar station IDs.
%       entrytime  - Datetime object (UTC) for start time.
%
%   Outputs:
%       station_data - Structure array with station metadata (timestamps, modes, bins).
%
%   Example:
%       station_data = getstation_metadata({'KDTX'}, datetime(2023, 10, 27, 12, 0, 0, 'TimeZone', 'UTC'));
%
%   See also: getNEXRADmetadata, queryVCPMode, getNEXRAD.

    % If the mode is unavailable, VCP215 is a good default, because it is a
    % fairly common mode and it covers most elevations 
    default_mode = 'VCP215';
    
    default_timestep = seconds(200); % used if timestamp metadata is unavailable
    
    % Maximum length of an event in seconds
    % If the entry time is less than this time before midnight, data from
    % the next day will be pulled as well
    max_eventtime_s = 1000;

    % Estimate max endtime
    max_endtime = (entrytime + seconds(max_eventtime_s));

    % Open a waitbar
    handleNEXRAD = waitbar(0,'Getting NEXRAD metadata...');
    
    % if timezone is empty, assume UTC
    if isempty(entrytime.TimeZone) || ~strcmp(entrytime.TimeZone,'UTC')
        entrytime.TimeZone = 'UTC';
    end

    % Convert entrytime to a date string for the day of the event
    dateStr = datestr(entrytime, 'yyyymmdd');
    
    % If the entrytime is just before midnight UTC, data from two days will
    % need to be pulled and merged together
    if day(entrytime) ~= day(max_endtime)
        dateStr_day2 = datestr(max_endtime, 'yyyymmdd');        
    end
           
    % Initialze the output struct
    station_data = struct();
    delete_station = false(numel(StationIDs),1);
    
    % Get station metadata
    for station_i = 1:numel(StationIDs)
        
        clear metadata
    
        % Update waitbar
        waitbar(station_i/numel(StationIDs),handleNEXRAD,['Getting NEXRAD Metadata for Station: ' StationIDs{station_i}]);
        
        % Store the station ID to the struct
        station_data(station_i).StationID = StationIDs{station_i};
        
        % Get a table of times and modes for the station
        [metadata, api_success] = getNEXRADmetadata(StationIDs{station_i}, dateStr);
        
        % If the data was retreived from online source and at least one of the timestamps is after entry, extract the timestamps of interest
        if api_success && any(metadata.TimestampUTC > entrytime)
            % Merge together day1 and day2, if needed
            if day(entrytime) ~= day(max_endtime)
                [metadata_day2, api_success] = getNEXRADmetadata(StationIDs{station_i}, dateStr_day2);
                metadata = [metadata; metadata_day2]; % assuming tables or structs are similar
            end

            % Add 30 seconds to the Timestamp data to account for rounding from the source
            if all(second(metadata.TimestampUTC)==0) % if all the second data is zero
                metadata.TimestampUTC = metadata.TimestampUTC + seconds(30);
            end

            % Find the begin and end indices        
            start_idx = max(1, find(metadata.TimestampUTC > entrytime,1)-1); % prevent 0 index
            end_idx = min(numel(metadata.TimestampUTC), find(metadata.TimestampUTC > max_endtime ,1));
            
            % Output struct data
            station_data(station_i).Timestamps = metadata.TimestampUTC(start_idx:end_idx);
            station_data(station_i).sensorMode = metadata.VCP_mode(start_idx:end_idx);

        else            
            % Populate timestamps with default values
            station_data(station_i).Timestamps = [entrytime:default_timestep:max_endtime]';
            
            % Set modes temporarily to Unknown
            station_data(station_i).sensorMode(1:size(station_data(station_i).Timestamps,1),1) = categorical({'Unknown'});
        end

        % Check for missing modes
        clear missing_i
        missing_i = (station_data(station_i).sensorMode == 'Unknown');
        
        % If all modes are missing, query user for a single mode
        % Use same mode for all timestamps, to avoid a lengthy process        
        station_timestep = station_data(station_i).Timestamps(2) - station_data(station_i).Timestamps(1);
        if all(missing_i)            
            station_data(station_i).sensorMode(1:size(station_data(station_i).Timestamps,1),1) = queryVCPMode(StationIDs{station_i}, station_data(station_i).Timestamps(1), station_data(station_i).Timestamps(end));
        
        % Otherwise check for specific missing modes and query user for each        
        else        
            missing_i = find(missing_i); % convert logical to index array
            for i = 1:length(missing_i)
                station_time_i = missing_i(i);
                station_data(station_i).sensorMode(station_time_i) = queryVCPMode(StationIDs{station_i}, station_data(station_i).Timestamps(station_time_i), station_data(station_i).Timestamps(station_time_i) + station_timestep);
            end                    
        end
        
        % Check for unavailable data
        clear unavailable
        unavailable = (station_data(station_i).sensorMode == 'No Data Available');
        
        % If there is no data for the station, remove it from the list
        if all(unavailable)
            delete_station(station_i) = true;
            
        % If some Timestamps have no data available, remove them        
        elseif any(unavailable)
            station_data(station_i).Timestamps(unavailable,:) = [];
            station_data(station_i).sensorMode(unavailable,:) = [];
        end
            
        % If all modes are Unknown, use default mode
        if all(station_data(station_i).sensorMode == 'Unknown')
            station_data(station_i).sensorMode(:) = default_mode;
            
        % Otherwise default any unknown values to the most common mode for the time period
        else
            station_data(station_i).sensorMode(station_data(station_i).sensorMode == 'Unknown') = mode(station_data(station_i).sensorMode);
        end        
    end
    
    % Delete stations with no data
    station_data(delete_station) = [];
        
   % Calculate bins
   for station_i = 1:length(station_data)

        % Calculate Time bin labels from timestamps
        station_data(station_i).datetime_binLabels = categorical(cellstr(datestr(station_data(station_i).Timestamps, 'HH:MM')));
        
        % Calculate elevation bins
        % If multiple VCP modes exist, get a superset of elevation bins
        station_elevations = [];
        for station_time_i = 1:length(station_data(station_i).sensorMode)
            station_elevations = [station_elevations getNEXRAD('elevations',station_data(station_i).sensorMode(station_time_i))];
        end
        station_elevations = unique(station_elevations);
        station_elevations = sort(station_elevations);
        
        % Save elevation bin labels
        station_data(station_i).elev_binLabels = categorical(station_elevations);
        
        % Calculate bin edges
        station_data(station_i).elev_binEdges = [-inf (station_elevations(1:end-1) + station_elevations(2:end)) / 2 inf];
        
   end
   
  % close waitbar
  close(handleNEXRAD)
    