function station_data = queryVCPMode(station_data, StationID, datetime_min, datetime_max)

    default_timestep = seconds(200); % used if timestamp metadata is unavailable
    
    % Get supported VCP modes (now already sorted)
    vcp_modes = getNEXRAD('supported_modes');

    % Convert cell array to a single string (comma-separated)
    vcp_modes_str = strjoin(vcp_modes, ',');

    % Add "No Data" option
    NoDataOption = {'No Data Available'};
    vcp_modes = [NoDataOption; vcp_modes];

    % Log query and supported modes
    logformat('User queried for radar station VCP modes', 'USER');
    logformat(sprintf('Supported Modes for data analysis: %s', vcp_modes_str), 'INFO');

    % Look at struct
    if ~isfield(station_data,'StationID')
        station_i = 1;
    elseif any(strcmp({station_data.StationID}, StationID))
        logformat('Unknown error: Station already present in station data', 'ERROR');
    else
        station_i = length(station_data) + 1;
    end
    
    % Format datetime strings
    datetime_min_str = datestr(datetime_min, 'yyyy-mmm-dd HH:MM:SS');
    datetime_max_str = datestr(datetime_max, 'yyyy-mmm-dd HH:MM:SS');

    % Create prompt string with instructions (as a cell array)
    prompt_str = {sprintf('Select VCP mode for station: ''%s''', StationID), ...
                  sprintf('Time Window: %s to %s (UTC)', datetime_min_str, datetime_max_str)};

    titleStr = sprintf('Select VCP mode: %s', StationID);

    [choice, ok_pressed] = listdlg('PromptString', prompt_str, ...
                                   'SelectionMode', 'single', ...
                                   'ListString', vcp_modes, ...
                                   'ListSize', [400, 300], ...
                                   'Name', titleStr);

    if ok_pressed
        
        % If no data found, no change
        if strcmp(vcp_modes{choice}, NoDataOption{1})
            logformat(sprintf('User found no data for %s', StationID), 'USER');
            station_data = station_data;
   
        % otherwise, store selected mode
        else
            station_data(station_i).StationID = StationID;
            
            % Log selection
            logformat(sprintf('User selected mode %s for %s', vcp_modes{choice}, StationID), 'USER');

            % Populate timestamps with default values
            station_data(station_i).Timestamps = [datetime_min:default_timestep:datetime_max]';
            
            % Store the selected mode
            station_data(station_i).sensorMode = categorical(repmat(vcp_modes(choice),size(station_data(station_i).Timestamps)));           
        end
    else
        logformat('User cancelled VCP mode selection', 'ERROR');        
    end


    
    