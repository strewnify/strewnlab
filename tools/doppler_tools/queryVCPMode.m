function VCP_mode = queryVCPMode(StationID, datetime_min, datetime_max)

    % Get supported VCP modes (now already sorted)
    vcp_modes = getNEXRAD('supported_modes');

    % Convert cell array to a single string (comma-separated)
    vcp_modes_str = strjoin(vcp_modes, ',');

    % Add "Unknown" option
    UnknownOption = {'Unknown'};
    vcp_modes = [UnknownOption; vcp_modes];

    % Add "No Data" option
    NoDataOption = {'No Data Available'};
    vcp_modes = [NoDataOption; vcp_modes];

    
    % Log query and supported modes
    logformat('User queried for radar station VCP modes', 'USER');
    logformat(sprintf('Supported Modes for data analysis: %s', vcp_modes_str), 'INFO');
   
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
       
        % Log choice
        switch vcp_modes{choice}
            case 'No Data Available'
                logformat(sprintf('User found no data for %s', StationID), 'USER');
                
            case 'Unknown'
                logformat(sprintf('User found unknown VCP mode for %s', StationID), 'USER');
                                
            otherwise
                 logformat(sprintf('User selected mode %s for %s', vcp_modes{choice}, StationID), 'USER');
        end
        
        VCP_mode = categorical(vcp_modes(choice));
   
    else
        logformat('User cancelled VCP mode selection', 'ERROR');        
    end


    
    