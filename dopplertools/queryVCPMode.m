function station_data = queryVCPMode(StationIDs, datetime_min, datetime_max)

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

    % Initialize results
    station_IDs = {};
    sensor_Modes = {};

    % Loop through each station and prompt user
    for i = 1:length(StationIDs)
        station_id = StationIDs{i};

        % Format datetime strings
        datetime_min_str = datestr(datetime_min, 'yyyy-mmm-dd HH:MM:SS');
        datetime_max_str = datestr(datetime_max, 'yyyy-mmm-dd HH:MM:SS');

        % Create prompt string with instructions (as a cell array)
        prompt_str = {sprintf('Select VCP mode for station %d of %d: ''%s''', ...
                             i, length(StationIDs), station_id), ...
                      sprintf('Time Window: %s to %s (UTC)', ...
                             datetime_min_str, datetime_max_str)};

        titleStr = sprintf('Select VCP mode: %s', station_id);
                         
        [choice, ok_pressed] = listdlg('PromptString', prompt_str, ...
                                       'SelectionMode', 'single', ...
                                       'ListString', vcp_modes, ...
                                       'ListSize', [400, 300], ...
                                       'Name', titleStr);

        if ok_pressed
            if strcmp(vcp_modes{choice}, NoDataOption{1})
                % Skip stations with "No Data" selection
                continue;
            end
        else
            logformat('User cancelled VCP mode selection', 'ERROR');
            break; % end without
        end

        % Log selection
        logformat(sprintf('User selected mode %s for %s', vcp_modes{choice}, station_id), 'USER');

        % Store selected station and mode
        station_IDs{end+1, 1} = station_id;
        sensor_Modes{end+1, 1} = vcp_modes{choice};
    end

    % Create table output
    station_data = table(station_IDs, sensor_Modes, 'VariableNames', {'StationID', 'sensorMode'});
end