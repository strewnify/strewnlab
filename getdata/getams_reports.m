%function [ AMS_data ] = getams(startyear, endyear, min_reports)
% AMS_DATA = GETAMS_PENDING( startdate, enddate )    Download pending reports from the AMS website.  

% if ~exist('AMS_data','var')
    % load API key
    strewnconfig

    % extend wait time for slow connections
    webread_options = weboptions('Timeout',webread_timeout);
    
    % Open a waitbar
    handleAMS = waitbar(0,'Downloading AMS reports...'); 

    % Disable table row assignment warning
    warning('off','MATLAB:table:RowsAddedExistingVars');

    % Set date limits
    % the result seems to be off by one day, so a day is added.
    now_UTC = datetime('now','TimeZone','UTC') + days(1);
    start_UTC = now_UTC - days(15);
    date_min = datestr(start_UTC,'YYYY-mm-DD');
    date_max = datestr(now_UTC,'YYYY-mm-DD');

    % Initialize row for output
    row = 0;
    startrow = 0;

    % Query online database
    %AMS_json = webread(['https://www.amsmeteors.org/members/api/open_api/get_close_reports?start+date=' date_min '&end_date=' date_max '&format=json&api_key=' getPrivate('AMS_APIkey')],webread_options);
    %AMS_json = webread(['https://www.amsmeteors.org/members/api/open_api/get_close_reports?start+date=' date_min '&end_date=' date_max '&pending_only=1&format=json&api_key=' getPrivate('AMS_APIkey')],webread_options);

    % start new year
    startrow = startrow + row;
    clear AMS_raw
    AMS_raw = struct2cell(AMS_json.result);
    numrows = size(AMS_raw,1);
    Variables = fieldnames(AMS_raw{1})';

    if ~exist('AMS_data','var')
        % columns --> 1   2       3      4      5      6      7     8      9    10  11  12 13 14 15 16     17 18 19 20 21 22 23 24 25 26 27 28 29     30      31    32     33     34     35     36     37     38     39 40  41     42     43 44     45     46
        InitCells = { 0 'text' 'text' 'text' 'text' 'text' 'text' 'text' 'text' NaT NaT 0  0  0  0  'text' 0  0  0  0  0  0  0  0  0  0  0  0  'text' 'text' 'text' 'text' 'text' 'text' 'text' 'text' 'text' 'text' 0  NaT 'text' 'text' 0  'text' 'text' 0 };
        AMS_data = cell2table(InitCells,'VariableNames',Variables);
    end

    % Convert data to table format
    for row = 1:numrows

         % Update waitbar
         waitbar(row/numrows,handleAMS,'Downloading AMS reports');

        %for column = 1:numel(Variables)
        for column = 1:42

            % get the variable type
            eval(['variable_type = class(AMS_raw{' num2str(row) '}.' Variables{column} ');'])

            % store data to table
            switch variable_type
                case 'char'
                    % Datetime
                    if (column == 10) || (column == 11) || (column == 40)
                        try
                            eval(['AMS_data.' Variables{column} '(' num2str(startrow + row) ',' num2str(1) ') = datetime(AMS_raw{' num2str(row) '}.' Variables{column} ');'])
                            eval(['AMS_data.' Variables{column} '_Excel(' num2str(startrow + row) ',' num2str(1) ') = exceltime(datetime(AMS_raw{' num2str(row) '}.' Variables{column} '));'])
                        catch
                            eval(['AMS_data.' Variables{column} '(' num2str(startrow + row) ',' num2str(1) ') = NaT;']);
                        end

                    % Character data
                    else
                        try
                            eval(['AMS_data.' Variables{column} '(' num2str(startrow + row) ',' num2str(1) ') = str2double(AMS_raw{' num2str(row) '}.' Variables{column} ');'])
                        catch
                            eval(['AMS_data.' Variables{column} '(' num2str(startrow + row) ',' num2str(1) ') = {AMS_raw{' num2str(row) '}.' Variables{column} '};'])    
                        end
                    end

                % Numeric data
                otherwise
                    try
                        eval(['AMS_data.' Variables{column} '(' num2str(startrow + row) ',' num2str(1) ') = str2double(AMS_raw{' num2str(row) '}.' Variables{column} ');']);
                    catch
                        eval(['AMS_data.' Variables{column} '(' num2str(startrow + row) ',' num2str(1) ') = {''''};']);
                    end
            end
        end
    end
% end

% Plot observation line projections

% Entry Points
figure
gstart = geoaxes;
hold on
title(['AMS Start Reports: ' datestr(now_UTC,'mmm DD, YYYY') ' to ' datestr(now_UTC,'mmm DD, YYYY')])
linelength_km = 500;
num_pending = size(AMS_data,1);
for obs_i = 1:num_pending
    [AMS_data.lat_startproj, AMS_data.long_startproj] = reckon(AMS_data.latitude, AMS_data.longitude, linelength_km*1000, AMS_data.initial_azimuth, getPlanet('ellipsoid_m'));
    plot(gstart,[AMS_data.latitude(obs_i) AMS_data.lat_startproj(obs_i)], [AMS_data.longitude(obs_i) AMS_data.long_startproj(obs_i)],'b-')
    plot(gstart,AMS_data.latitude(obs_i), AMS_data.longitude(obs_i), 'ko')
end

% End Points
figure
gend = geoaxes;
hold on
title(['AMS End Reports: ' datestr(now_UTC,'mmm DD, YYYY') ' to ' datestr(now_UTC,'mmm DD, YYYY')])
linelength_km = 500;
num_pending = size(AMS_data,1);
for obs_i = 1:num_pending
    [AMS_data.lat_endproj, AMS_data.long_endproj] = reckon(AMS_data.latitude, AMS_data.longitude, linelength_km*1000, AMS_data.final_azimuth,getPlanet('ellipsoid_m'));
    plot(gend,[AMS_data.latitude(obs_i) AMS_data.lat_endproj(obs_i)],[AMS_data.longitude(obs_i) AMS_data.long_endproj(obs_i)],'b-')
    plot(gend,AMS_data.latitude(obs_i),AMS_data.longitude(obs_i),'ko')
end


% % Plot observation line projections
% figure
% hold on
% title(['AMS End Reports: ' datestr(now_UTC,'mmm DD, YYYY') ' to ' datestr(now_UTC,'mmm DD, YYYY')])
% load coastlines
% plot(coastlon, coastlat)
% linelength_km = 500;
% num_pending = size(AMS_data,1);
% for obs_i = 1:num_pending
%     [AMS_data.lat_endproj, AMS_data.long_endproj] = reckon(AMS_data.latitude, AMS_data.longitude, linelength_km*1000, AMS_data.final_azimuth,getPlanet('ellipsoid_m'));
%     plot([AMS_data.longitude(obs_i) AMS_data.long_endproj(obs_i)], [AMS_data.latitude(obs_i) AMS_data.lat_endproj(obs_i)],'b-')
%     plot(AMS_data.longitude(obs_i),AMS_data.latitude(obs_i),'ko')
% end

% % Plot observation line projections
% figure
% hold on
% title(['AMS Start Reports: ' datestr(now_UTC,'mmm DD, YYYY') ' to ' datestr(now_UTC,'mmm DD, YYYY')])
% load coastlines
% plot(coastlon, coastlat)
% linelength_km = 500;
% num_pending = size(AMS_data,1);
% for obs_i = 1:num_pending
%     [AMS_data.lat_startproj, AMS_data.long_startproj] = reckon(AMS_data.latitude, AMS_data.longitude, linelength_km*1000, cellfun(@str2num,AMS_data.initial_azimuth), planet);
%     plot([AMS_data.longitude(obs_i) AMS_data.long_startproj(obs_i)],[AMS_data.latitude(obs_i) AMS_data.lat_startproj(obs_i)],'b-')
%     plot(AMS_data.longitude(obs_i), AMS_data.latitude(obs_i), 'ko')
% end

% Re-enable table row assignment warning
warning('on','MATLAB:table:RowsAddedExistingVars');

% close waitbar
close(handleAMS)

% Write data to Excel file
temporary = AMS_data;
AMS_xlsdata = [temporary.Properties.VariableNames; table2cell(temporary)];
output_filename = [datestr(now,'yyyymmddHHMM') '_AMS_PendingReports'];
cd(getSession('folders','scheduledfolder')) % change directory
xlswrite(output_filename,AMS_xlsdata)
cd(getSession('folders','mainfolder')) % return to main folder
