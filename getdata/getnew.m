function [ NewEvents, output_filename, numnew ] = getnew( dayhistory )
% [NEW_EVENTS] =  GETNEW (DAYHISTORY)   Download event data from
% online sources, from the last x days (specified by DAYHISTORY), compare 
% to the database, and add new events.

% dayhistory = 4; msgbox('GETNEW Test Mode')

% Load config file
if ~exist('check_configloaded','var') || ~check_configloaded
    strewnconfig
end

nowtime_utc = datetime('now','TimeZone','UTC'); 
datetimestring = datestr(now,'yyyymmddHHMM');
startyear = year(nowtime_utc-days(dayhistory));
endyear = year(nowtime_utc);

% Load the database (includes backup)
load_database

% Get data from the CNEOS fireball database
if ~exist('CNEOS_data','var')
    CNEOS_data = getcneos();    
end

% Get data from the AMS fireball database
if ~exist('AMS_data','var')
    AMS_data = getams(startyear,endyear,5, 2);
end

% Get data from the ASGARD site
if ~exist('ASGARD_data','var')
    ASGARD_data = getasgard(dayhistory);
end

% Add source identifiers
CNEOS_data.DataSource(:) = {'CNEOS'};
AMS_data.DataSource(:) = {'AMS'};
ASGARD_data.DataSource(:) = {'ASGARD'};

% Merge the data from all sources
Merge_data = outerjoin(AMS_data,CNEOS_data,'MergeKeys',true);
Merge_data = outerjoin(Merge_data,ASGARD_data,'MergeKeys',true);

%new = find(Merge_data.Datetime > (datetime('now')-days(dayhistory)));

qualifiers = {'EventID','DataSource'};
new = find(~ismember(Merge_data(:,qualifiers),sdb_Events(:,qualifiers)));

% Open a waitbar
handleNewEvents = waitbar(0,'Downloading CNEOS Fireball Data...'); 
numnew = numel(new);

% If events found, summarize and export
if numnew > 0
    
    for i = 1:numnew
        % Update waitbar
        waitbar(i/numnew,handleNewEvents,'Populating Location Data...');
        try
            Merge_data.Location(new(i),1) = {getlocation(Merge_data.LAT(new(i)),Merge_data.LONG(new(i)))};
        catch
            Merge_data.Location(new(i),1) = {'-'};
        end

        % Add a link to Google Maps for each line
        Merge_data.HyperMap(new(i),1) = {['https://maps.google.com/?q=' num2str(Merge_data.LAT(new(i)),'%f') '%20' num2str(Merge_data.LONG(new(i)),'%f')]};
    end

    % Get current time
    ProcessDatetime = datetime('now');
    
    % This code can provide specific variables to the database, to limit size
    % Variables = {'EventID';'DataSource';'Datetime';'Location';'NumReports';'LAT';'LONG';'RadiatedEnergy';'ImpactEnergy';'vx';'vy';'vz';'Mass';'Speed';'Bearing';'Incidence';'Altitude';'ProcessDate';'Hyperlink1';'Hyperlink2';'HyperMap'};
    % NewEvents = Merge_data(new,Variables);
    
    % Filter new events and sort
    NewEvents = Merge_data(new,:);
    NewEvents = sortrows(NewEvents,'EventID');
    
    % Set dates (feature TBD)
    NewEvents.AddDate(:) = ProcessDatetime;
    NewEvents.UpdateDate(:) = ProcessDatetime;
    
    % Records without a processing time are assigned current time
    NewEvents.ProcessDate(isnat(NewEvents.ProcessDate)) = ProcessDatetime;

    % Append data to database and sort
    sdb_Events = [sdb_Events; NewEvents];
    sdb_Events = sortrows(sdb_Events,'EventID','ascend');
    
    % Write data to Excel file
    temporary = NewEvents;
    temporary.Datetime = datestr(temporary.Datetime,'mm/dd/yyyy HH:MM:SS UTC');
    NewEvents_xlsdata = [temporary.Properties.VariableNames; table2cell(temporary)];
    output_filename = [getSession('folders','scheduledfolder') '\' datetimestring '_NewEventData.csv'];
    
    cd(getSession('folders','scheduledfolder'))
    writecell(NewEvents_xlsdata, output_filename)
    % xlswrite(output_filename_short,NewEvents_xlsdata)
    % open file in Excel
    % winopen(output_filename)
    cd(getSession('folders','mainfolder'))
    
    % Save database
    logformat(sprintf('%0.0f new events imported into %s',numnew,DatabaseFilename),'DATA')
    save_database
    
% otherwise, report no events
else
    logformat('No new events found.')
    output_filename = 'NA';
    NewEvents = array2table(zeros(0,0)); % empty table to satify function return
end

% close waitbar
close(handleNewEvents)

