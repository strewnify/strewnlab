function station_data = getstation_metadata(StationIDs,entrytime)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here

    % If the mode is unavailable, VCP215 is a good default, because it is a
    % fairly common mode and it covers most elevations 
    default_mode = 'VCP215';
    
    % Maximum length of an event in seconds
    % If the entry time is less than this time before midnight, data from
    % the next day will be pulled as well
    max_eventtime_s = 1000;

    % Estimate max endtime
    max_endtime = (entrytime + seconds(max_eventtime_s));
    
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
    
    for station_i = 1:numel(StationIDs)
        
        clear metadata
        
        % Get a table of times and modes for the station
        [metadata, api_success] = getNEXRADmetadata(StationIDs{station_i}, dateStr);
        
        % If the data was retreived from online source, extract the timestamps of interest
        if api_success
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
            station_data(station_i).StationID = StationIDs{station_i};
            station_data(station_i).Timestamps = metadata.TimestampUTC(start_idx:end_idx);
            station_data(station_i).sensorMode = metadata.VCP_mode(start_idx:end_idx);
            
        % Get station data from user
        else
            logformat
            station_data = queryVCPMode(station_data, StationIDs{station_i}, entrytime, max_endtime);
        end
    end
   
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
    