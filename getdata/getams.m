function [ AMS_data ] = getams(startyear, endyear, min_reports, min_duration)
% AMS_DATA = GETAMS( MINREPORTS )    Download the American Meteor Society database.  
% MINREPORTS - only events with more than this number of reports will be returned
% Solar elevation is calculated and daytime events are always reported, regardless of duration

% Load settings
strewnconfig

% extend wait time for slow connections
webread_options = weboptions('Timeout',webread_timeout);

% Open a waitbar
handleAMS = waitbar(0,'Downloading AMS reports...'); 

% Disable table row assignment warning
warning('off','MATLAB:table:RowsAddedExistingVars');

% Initialize row for output
row = 0;
startrow = 0;

for year_index = startyear:endyear
    
   try
        % Query online database
        AMS_json = webread([URL_AMS_API 'year=' num2str(year_index) '&min_reports=' num2str(min_reports) '&format=json&api_key=' AMS_APIkey],webread_options);
        
        % start new year
        startrow = startrow + row;
        clear AMS_raw
        AMS_raw = struct2cell(AMS_json.result);
        AMS_raw_pageid = fieldnames(AMS_json.result);        
        numrows = size(AMS_raw,1);
        Variables = fieldnames(AMS_raw{1})';
        InitCells = { 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 'text' 0 datetime('now') datetime('now') 'text' 0};

        if ~exist('AMS_data','var')
            AMS_data = cell2table(InitCells,'VariableNames',Variables);
        end

        % Convert data to table format
        for row = 1:numrows

             % Update waitbar
             waitbar(row/numrows,handleAMS,['Downloading ' num2str(year_index) ' AMS reports']);

             % Get AMS page ID
             AMS_data.AMS_event_id(startrow + row) = AMS_raw_pageid(row);
             
            for column = 1:numel(Variables)
                if (column == 21) || (column == 25)
                    eval(['AMS_data.' Variables{column} '(' num2str(startrow + row) ',' num2str(1) ') = {AMS_raw{' num2str(row) '}.' Variables{column} '};']);
                elseif (column == 23) || (column == 24)
                    try
                        eval(['AMS_data.' Variables{column} '(' num2str(startrow + row) ',' num2str(1) ') = datetime(AMS_raw{' num2str(row) '}.' Variables{column} ');']);
                    catch
                        eval(['AMS_data.' Variables{column} '(' num2str(startrow + row) ',' num2str(1) ') = datetime(' year_index ',1,1);']); % invalid dates default to noon on January 1
                    end
                else
                    eval(['AMS_data.' Variables{column} '(' num2str(startrow + row) ',' num2str(1) ') = str2double(AMS_raw{' num2str(row) '}.' Variables{column} ');']);
                end
            end
        end
        
    catch
        warning(['AMS data not found for ' num2str(year_index) '!  No reports exist or internet connection.'])
    end
    
end

% Sort table by event ID
%AMS_data = sortrows(AMS_data,-1);

% Post processing
AMS_data(AMS_data.num_reports_for_options <= 0,:) = [];  % Delete records with no trajectory
AMS_data.Datetime = AMS_data.avg_date_utc;
AMS_data.LAT = round(AMS_data.end_lat,4);
AMS_data.LONG = round(AMS_data.end_long,4);
AMS_data.SolarElev = solarelevation(AMS_data.LAT,AMS_data.LONG,AMS_data.Datetime); % Calculate solar elevation
AMS_data(AMS_data.SolarElev < 0 & AMS_data.avg_duration < min_duration,:) = [];  % Delete night events below min duration
AMS_data.Altitude = round(AMS_data.end_alt./1000,3);
[temp_distance_meters, temp_bearing] = distance(AMS_data.start_lat,AMS_data.start_long,AMS_data.end_lat,AMS_data.end_long,planet.ellipsoid_m);
AMS_data.CurveDist = temp_distance_meters ./ 1000; % convert meters to kilometers
AMS_data.Bearing = round(temp_bearing,3);
clear temp_distance
clear temp_bearing
AMS_data.Incidence = round(atand(1000.*AMS_data.CurveDist./(AMS_data.start_alt-AMS_data.end_alt)),3);
AMS_data.NumReports = AMS_data.num_reports_for_options;

% Impact Energy rough estimate
AMS_data.ImpactEnergy_Est = AMS_data.NumReports ./ 10000;

% trash "event_id" from AMS
AMS_data.event_id = [];

% Assign EventID
AMS_data.EventID = arrayfun(@eventidcalc,AMS_data.LAT,AMS_data.LONG,AMS_data.Datetime,'UniformOutput',false);

% Add Hyperlinks
for row = 1:size(AMS_data,1)
    AMS_data.Hyperlink1(row) = strcat('https://fireball.amsmeteors.org/members/imo_view/',{regexprep(AMS_data.AMS_event_id{row},'(?:_)','/')});
end

% Re-enable table row assignment warning
warning('on','MATLAB:table:RowsAddedExistingVars');

% Log
logformat(sprintf('%0.0f records retrieved from AMS',size(AMS_data,1)),'DATA')

% close waitbar
     close(handleAMS)
