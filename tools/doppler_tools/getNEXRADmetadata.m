function [metadata, success] = getNEXRADmetadata(StationID, dateStr)
    % getNEXRADVCPModes Retrieves VCP mode and scan time data from NOAA NEXRAD inventory.
    %
    %   vcp_data = getNEXRADVCPModes(station_id, date_str)
    %
    %   Inputs:
    %       StationIDs - Radar station ID (e.g., 'KDTX').
    %       entrytime  - Datetime of the entry time.
    %
    %   Outputs:
    %       vcp_data   - Table containing VCP mode data.
    % Data is extracted in CSV format, as follows:
    %   'ZTIME,OPMODE,VCP
    %   20180117 00:08,B,31
    %   20180117 00:18,B,31
    %   20180117 00:28,B,31
    %   20180117 00:38,B,31
    %   20180117 00:47,B,31
    %   ...

    % This NOAA site returns metadata for a station on a given day
    url = sprintf('https://www.ncdc.noaa.gov/nexradinv-ws/csv?siteid=%s&dsi=6500&product=LIST&dateRange=%s&attributes=mode', StationID, dateStr);
    logformat(sprintf('Attempting to pull metadata from NOAA server: <a href="%s">Metadata Link</a>',url),'DATA')
    
    temp_fullpath = [tempname,'.csv'];
    
    preventAbuse(4,500); % rate limit requests to every 4 seconds, max of 500 calls
    
    try
        csv_data = webread(url);

        % Write the CSV data to a temporary file
        fid = fopen(temp_fullpath, 'w');
        fprintf(fid, '%s', csv_data);
        fclose(fid);

        % Read the CSV data from the temporary file
        metadata = readtable(temp_fullpath, 'Delimiter',{','}, 'MissingRule', 'fill');

        % Delete the temporary file
        delete(temp_fullpath);

        % Rename the ZTIME column to TimestampUTC and convert to datetime array
        if ismember('ZTIME', metadata.Properties.VariableNames)
            metadata.Properties.VariableNames{'ZTIME'} = 'TimestampUTC';
            metadata.TimestampUTC = datetime(metadata.TimestampUTC, 'InputFormat', 'yyyyMMdd HH:mm', 'TimeZone','UTC');
        else
            logformat('ZTIME column not found in the table.','DATA');
        end

        % Convert OPMODE to categorical
        if ismember('OPMODE', metadata.Properties.VariableNames)
            metadata.OPMODE = categorical(metadata.OPMODE);
        else
            logformat('Unexpected data format. OPMODE column not found in the table.','DEBUG');
        end

        % Rename the VCP column to VCP_mode
        if ismember('VCP', metadata.Properties.VariableNames)
            metadata.Properties.VariableNames{'VCP'} = 'VCP_mode';
            % Convert from double to char and add VCP before (example 'VCP31')
            metadata.VCP_mode = strcat('VCP', string(metadata.VCP_mode));
        else
            logformat('Unexpected data format. VCP column not found in the table.','WARN');
            error('go to catch') % prevents logformat from closing the waitbar
        end

        % Get supported VCP modes (sorted cell array of strings)
        vcp_modes = getNEXRAD('supported_modes');

        % strcmp and replace unknown modes with 'Unknown'
        metadata.VCP_mode = categorical(metadata.VCP_mode);

        for i = 1:height(metadata)
            if ~ismember(char(metadata.VCP_mode(i)), vcp_modes)
                metadata.VCP_mode(i) = categorical({'Unknown'});
            end
        end
        
        success = true;
        
    catch ME
        success = false;
        logformat(sprintf('Error retrieving VCP data for station %s and date %s: %s', StationID, dateStr, ME.message),'WARN');
        metadata = table(); % Return an empty table in case of error
        if exist(temp_fullpath, 'file') % Make sure that the temporary file is deleted even if error occurs
            delete(temp_fullpath);
        end                
    end
end