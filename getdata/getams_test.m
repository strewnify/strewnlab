function [ AMS_data, AMS_json] = getams_test(startdate,enddate)
% AMS_DATA = GETAMS( DAYHISTORY )    Download events from the American Meteor Society database.

% Load config
strewnconfig

% AMS connectivity disable
if getConfig('ams_disable')
    logformat('AMS connectivity is disabled by default until further notice.','ERROR')

% Run the GETAMS script
else

    % extend wait time for slow connections
    webread_options = weboptions('Timeout',webread_timeout);

    min_reports = 10; % reports threshold
    nowtime_utc = datetime('now','TimeZone','UTC');

    % if timezone is empty, assume UTC
    if isempty(startdate.TimeZone) || ~strcmp(startdate.TimeZone,'UTC')
        startdate.TimeZone = 'UTC';
    end
    if isempty(enddate.TimeZone) || ~strcmp(enddate.TimeZone,'UTC')
        enddate.TimeZone = 'UTC';
    end

    % Clip min date for source database
    mindate = datetime(2000,01,01,'TimeZone','UTC');
    if isnat(startdate) || startdate < mindate
        startdate = mindate;
    end
    if isnat(enddate) || enddate > nowtime_utc
        enddate = nowtime_utc;
    end
    startyear = year(startdate); 
    endyear = year(nowtime_utc);

    % Open a waitbar
    handleAMS = waitbar(0,'Downloading AMS reports...'); 

    % Disable table row assignment warning
    warning('off','MATLAB:table:RowsAddedExistingVars');

    % Initialize row for output
    row = 0;
    startrow = 0;
    years = startyear:endyear;

    for year_idx = 1:length(years)

       try
            % Query online database
            download = webread([URL_AMS_API 'year=' num2str(years(year_idx)) '&min_reports=' num2str(min_reports) '&format=json&api_key=' getPrivate('AMS_APIkey')],webread_options);
            download.year = years(year_idx); % assign year to struct
            AMS_json(year_idx) = download; % save year json to struct
            clear download        

            % start new year
            startrow = startrow + row;
            clear AMS_raw
            AMS_raw = struct2cell(AMS_json(year_idx).result);
            AMS_raw_pageid = fieldnames(AMS_json(year_idx).result);        
            numrows = size(AMS_raw,1);
            Variables = fieldnames(AMS_raw{1})';
            InitCells = { 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 'text' 0 nowtime_utc nowtime_utc 'text' 0};

            if ~exist('AMS_data','var')
                AMS_data = cell2table(InitCells,'VariableNames',Variables);
            end

            % Convert data to table format
            for row = 1:numrows

                 % Update waitbar
                 waitbar(row/numrows,handleAMS,['Downloading ' num2str(years(year_idx)) ' AMS reports']);

                 % Get AMS page ID
                 AMS_data.pageid(startrow + row) = {regexprep(AMS_raw_pageid{row},'(?:_)','/')};

                for column = 1:numel(Variables)
                    if (column == 21) || (column == 25)
                        eval(['AMS_data.' Variables{column} '(' num2str(startrow + row) ',' num2str(1) ') = {AMS_raw{' num2str(row) '}.' Variables{column} '};']);
                    elseif (column == 23) || (column == 24)
                        try
                            eval(['AMS_data.' Variables{column} '(' num2str(startrow + row) ',' num2str(1) ') = datetime(AMS_raw{' num2str(row) '}.' Variables{column} ',''TimeZone'',''UTC'');']);
                        catch
                            eval(['AMS_data.' Variables{column} '(' num2str(startrow + row) ',' num2str(1) ') = datetime(' years(year_idx) ',1,1,''TimeZone'',''UTC'');']); % invalid dates default to noon on January 1
                        end
                    else
                        eval(['AMS_data.' Variables{column} '(' num2str(startrow + row) ',' num2str(1) ') = str2double(AMS_raw{' num2str(row) '}.' Variables{column} ');']);
                    end
                end
            end

        catch
            logformat(['AMS data not found for ' num2str(years(year_idx)) '!  No reports exist or internet connection.'],'WARN')
        end

    end

    % Rename group 1
    source_varnames = [{'event_id'} {'average_magnitude'} {'start_lat'} {'start_long'} {'start_alt'} {'end_lat'} {'end_long'} {'end_alt'} {'impact_lat'} {'impact_long'}];
    sdb_varnames = [{'AMS_eventid'} {'average_magnitude'} {'entry_Lat'} {'entry_Long'} {'entry_Height_m'} {'end_Lat'} {'end_Long'} {'end_Height_m'} {'impact_Lat'} {'impact_Long'}];

    % Rename group 2
    source_varnames = [source_varnames {'epicenter_lat'} {'epicenter_long'} {'threshold'} {'min_hour_diff'} {'comp_precision'} {'min_rating'} {'end_threshold'} {'optimized_ratings'} {'num_reports_for_options'} {'RA_dec'}];
    sdb_varnames = [sdb_varnames {'epicenter_lat'} {'epicenter_long'} {'threshold'} {'min_hour_diff'} {'comp_precision'} {'min_rating'} {'end_threshold'} {'optimized_ratings'} {'NumReports'} {'RA_dec'}];

    % Rename group 3
    source_varnames = [source_varnames {'RA'} {'d_Dec'} {'avg_date_utc'} {'avg_date_local'} {'timezone'} {'avg_duration'} {'pageid'}];
    sdb_varnames = [sdb_varnames {'RA'} {'d_Dec'} {'DatetimeUTC'} {'avg_date_local'} {'source_timezone'} {'duration_s'} {'pageid'}];

    AMS_data = renamevars(AMS_data, source_varnames, sdb_varnames);

    % Post processing
    AMS_data(AMS_data.NumReports <= 0,:) = [];  % Delete records with no trajectory

    % Impact Energy rough estimate
    AMS_data.ImpactEnergyEst_kt = AMS_data.NumReports ./ 10000;

    % Assign Event identifiers
    AMS_data.EventID_nom = arrayfun(@eventid,AMS_data.end_Lat,AMS_data.end_Long,AMS_data.DatetimeUTC,'UniformOutput',false);
    pageid_parts = split(AMS_data.pageid,'/');
    AMS_data.SourceKey = strcat(pageid_parts(:,3),repmat({'-'},size(pageid_parts,1),1),pageid_parts(:,2));

    % Add Hyperlinks
    for row = 1:size(AMS_data,1)
        AMS_data.Hyperlink1(row) = {['https://fireball.amsmeteors.org/members/imo_view/' AMS_data.pageid{row}]};
    end

    % Filter events before dayhistory
    AMS_data = AMS_data(AMS_data.DatetimeUTC >= startdate & AMS_data.DatetimeUTC <= enddate,:);

    % Add timestamp
    AMS_data.DateAccessed(:) = nowtime_utc; 

    % Re-enable table row assignment warning
    warning('on','MATLAB:table:RowsAddedExistingVars');

    % Log
    logformat(sprintf('%0.0f records retrieved from AMS',size(AMS_data,1)),'DATA')

    % close waitbar
    close(handleAMS)
end