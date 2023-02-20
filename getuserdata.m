function [ File_data ] = getuserdata( filename )
% [ FILE_DATA ]  = GETUSERDATA( FILENAME )  
% Import meteoritic data from spreadsheet.

% Parse filename
filetype = extractBefore(filename,'.');
if isempty(filetype)
    error('Filename extension missing.')
end

% File data format
switch filetype
    case 'AllEventData'
        variable_row = 4; 
        data_row = 6;

    case 'AllLandings'
        variable_row = 1; 
        data_row = 2;

    otherwise
        error('File type not supported.')
end

% Create or update waitbar
WaitbarHandle = waitbar(0,['Opening ' filename '...']);

% Setup spreadsheet import options
opts = detectImportOptions(filename);
opts.VariableNamesRange = ['A' num2str(variable_row)];
opts.DataRange = ['A' num2str(data_row)];

% Open Event Data File
File_data = readtable(filename,opts,'ReadVariableNames',true);
User_numrecords = size(File_data,1);

% Remove skip columns
User_varnames = File_data.Properties.VariableNames;
for name_i = 1:numel(User_varnames)
    if ~isempty(strfind(User_varnames{name_i},'skip_'))
        File_data(:,User_varnames{name_i}) = [];
        %User_data = removevars(User_data, User_varnames{name_i});
    end
end

% Choose file type
switch filetype
    case 'AllEventData'

        % Unit conversions
        File_data.DatetimeUTC = datetime(File_data.DatetimeUTC,'TimeZone','UTC'); % add timezone to datetimes
        
        % Post processing - complex functions for each record
        for record_i = 1:User_numrecords

            % Update waitbar
            waitbar(record_i/User_numrecords,WaitbarHandle,'Loading Fireball Events from spreadsheet...');
            
            if ~isnan(File_data.timezone_offset)
                File_data.Timezone(record_i,1) = {[num2str(File_data.timezone_offset,'%+.2d') ':00']};
                File_data.Datetime_local(record_i,1) = datetime(File_data.DatetimeUTC(record_i),'TimeZone',File_data.Timezone{record_i});        

            elseif ~isnan(File_data.ref_Lat(record_i)) && ~isnan(File_data.ref_Long(record_i))
                File_data.Timezone(record_i,1) = {[num2str(-timezone(File_data.ref_Long(record_i)),'%+.2d') ':00']};
                File_data.Datetime_local(record_i,1) = datetime(File_data.DatetimeUTC(record_i),'TimeZone',File_data.Timezone{record_i});                        
            else
                File_data.Timezone(record_i,1) = {'+00:00'};
                File_data.Datetime_local(record_i,1) = NaT(1,'TimeZone','+00:00');
            end
        end

        % Assign keys
        File_data.SourceKey = arrayfun(@num2str,File_data.SourceKey,'UniformOutput',false);
        File_data.EventID_nom = arrayfun(@eventid,File_data.ref_Lat,File_data.ref_Long,File_data.DatetimeUTC,'UniformOutput',false);

        % Import event data
        waitbar(0.5,WaitbarHandle,'Loading Event Data...');

        % Generate a filename for saving files
        %User_data.FilenameString = matlab.lang.makeValidName(SimulationName,'ReplacementStyle','delete');

        % Get event ground elevation data
        % try
        %     ground = getElevations(nom_lat, nom_long, 'key', GoogleMapsAPIkey );
        %     if ground < 0
        %         error('Ground level is below sea level.')
        %     end
        % catch
        %     warning('Google Maps API failure.  User queried for ground elevation.')
        %     usersuccess = false;
        %     while ~usersuccess
        %         user_ground = inputdlg('Elevation data not accessible. Please enter ground elevation in meters:','Google API Failure',1,{'0'});        
        %         ground = str2double(cell2mat(user_ground)); 
        %         if isnan(ground)
        %             usersuccess = false;
        %         else
        %             usersuccess = true;
        %         end
        %     end
        %     clear usersuccess
        %     
        % end

        % Update waitbar
        waitbar(1,WaitbarHandle,'Event data loaded from file.');
        pause(1)
        
    case 'AllLandings'
        
        % Unit conversions
        File_data.DatetimeUTC = datetime(File_data.year,1,1,'TimeZone','UTC'); % add timezone to datetimes
        
        % Post processing - complex functions for each record
        for record_i = 1:User_numrecords

            % Update waitbar
            waitbar(record_i/User_numrecords,WaitbarHandle,'Loading Fireball Events from spreadsheet...');
            
            % Assign EventID
            File_data.EventID_nom(record_i,1) = {eventid(File_data.ref_Lat(record_i),File_data.ref_Long(record_i),File_data.DatetimeUTC(record_i),'unwitnessed', File_data.Name{record_i}, 'M')};
            File_data.SourceKey = File_data.EventID_nom;
        end

        % Update waitbar
        waitbar(1,WaitbarHandle,'Event data loaded from file.');
        pause(1)
        
    otherwise
        error('Invalid input file type specified.')
end

% Filter events before dayhistory
File_data = File_data(File_data.DatetimeUTC >= startdate & File_data.DatetimeUTC <= enddate,:);

% Standardize output data
File_data.DateAccessed(:) = nowtime_utc; % Add timestamp
File_data = standardize_tbdata(File_data); % Convert units and set column order

% Re-enable table row assignment warning
warning('on','MATLAB:table:RowsAddedExistingVars');

% Log
logformat(sprintf('%0.0f records retrieved from %s',size(File_data,1),filename),'DATA')

% close waitbar
 close(WaitbarHandle)
