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
%         station_data(station_i).Timestamps = metadata.TimestampUTC(start_idx:end_idx);
        station_data(station_i).sensorMode = metadata.VCP_mode(start_idx:end_idx);
 
        % Temporary Code
        station_data(station_i).sensorMode = mode(station_data(station_i).sensorMode);
    end
    
            
       % Temporary Code
        station_data = struct2table(station_data);
    
    