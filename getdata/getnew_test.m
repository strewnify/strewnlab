%function [ NewEvents, output_filename, num_new, num_updated ] = getnew_test( dayhistory )
% [NEW_EVENTS] =  GETNEW (DAYHISTORY)   Download event data from
% online sources, from the last x days (specified by DAYHISTORY), compare 
% to the database, and add new events.

% Load settings
strewnconfig
[~,codefilename,~] = fileparts(mfilename('fullpath'));
diary([logfolder codefilename '_log.txt'])  
diary on
logformat('Getting new events.')

% Disable table row assignment warning
warning('off','MATLAB:table:RowsAddedExistingVars');

%dayhistory = 15000;
dayhistory = 30;

%Load the database
load_database_test

% Query user for databases
SourceList = fieldnames(sdb_ImportData);
[getsources,usersuccess] = listdlg('ListString',SourceList,'SelectionMode','multiple','Name','Select Sources', 'OKString','Load','PromptString','Select Sources for Import:','ListSize',[300,300]);
if ~usersuccess
    clear getsources
    clear eventindex
    logformat('No sources selected. Exit program.','ERROR')
end
GetSourceList = SourceList(getsources);

% Define time period
nowtime_utc = datetime('now','TimeZone','UTC'); 
startdate_utc = nowtime_utc - days(dayhistory);
enddate_utc = nowtime_utc;
startyear = year(nowtime_utc-days(dayhistory));
endyear = year(nowtime_utc);

% Initialize counters
num_reviewed = 0;
num_new = 0;
num_newsources = 0;
num_updated = 0;

% Open a waitbar
handleNewEvents = waitbar(0,'Loading Data...');
pause(0.2)

% Get data from each database requested
for source_i = 1:numel(getsources)

    source_name = GetSourceList{source_i}; % name of the source database
    dayhistory_max = sdb_ImportData.(source_name).dayhistory_max; % maximum day history available from source
    startdate_min_utc = sdb_ImportData.(source_name).startdate_min_utc; % earliest date in source
    startdate_eff = max([startdate_utc, (nowtime_utc - days(dayhistory_max)), startdate_min_utc]);
        
    % set to false, to skip import and re-process old data
    getnewdata_config = true;
    standardize_config = true;
    db_import_config = true;
    
    if getnewdata_config
        % Clear existing data
        sdb_ImportData.(source_name).OldDataRaw = sdb_ImportData.(source_name).LatestDataRaw; 
        sdb_ImportData.(source_name).OldData = sdb_ImportData.(source_name).LatestData; 

        sdb_ImportData.(source_name).LatestDataRaw = []; 
        sdb_ImportData.(source_name).LatestData = []; 

        % Arbitrate data source get function, and get data
        try
            if strcmp(sdb_ImportData.(source_name).source_filename,'none')
                sdb_ImportData.(source_name).LatestDataRaw = sdb_ImportData.(source_name).getfunction(startdate_eff,enddate_utc);        
            else
                sdb_ImportData.(source_name).LatestDataRaw = sdb_ImportData.(source_name).getfunction(sdb_ImportData.(source_name).source_filename);
            end

        catch
            logformat(sprintf('Error in retrieving %s records.',source_name),'DEBUG')
        end
    end
    
    % if records were retrieved, clean the data and import events
    if ~isempty(sdb_ImportData.(source_name).LatestDataRaw)
        % Standardize the data
        if standardize_config
%         try
            % Convert units,arbitrate missing signals, re-order columns
            sdb_ImportData.(source_name).LatestData = tbdata_standardize(sdb_ImportData,source_name,'LatestDataRaw',sdb_Variables); 
            import_ok = true;
%         catch
%             import_ok = false;
%             logformat(sprintf('Error in standardizing %s records.',source_name),'DEBUG')
%         end
        end
    end
    
    % Import data into local database
    if db_import_config && ~isempty(sdb_ImportData.(source_name).LatestData) && import_ok
        sdb_MeteorData = importevents(sdb_MeteorData, sdb_ImportData, source_name, handleNewEvents);
    end
    %logformat(sprintf('',),'DATA');
end


% % If events found, summarize and generate report
% if num_new > 0
%     
%     for i = 1:num_new
%         % Update waitbar
%         waitbar(i/num_new,handleNewEvents,'Populating Location Data...');
%         try
%             Merge_data.Location(new(i),1) = {getlocation(Merge_data.LAT(new(i)),Merge_data.LONG(new(i)))};
%         catch
%             Merge_data.Location(new(i),1) = {'-'};
%         end
%     end
% 
%     % Get current time
%     ProcessDatetime = datetime('now','TimeZone','UTC');
%     
%     % This code can provide specific variables to the database, to limit size
%     % Variables = {'EventID';'DataSource';'Datetime';'Location';'NumReports';'LAT';'LONG';'RadiatedEnergy';'ImpactEnergy';'vx';'vy';'vz';'Mass';'Speed';'Bearing_deg';'Incidence';'Altitude';'ProcessDate';'Hyperlink1';'Hyperlink2'};
%     % NewEvents = Merge_data(new,Variables);
%     
%     % Filter new events and sort
%     NewEvents = Merge_data(new,:);
%     NewEvents = sortrows(NewEvents,'EventID');
%     
%     % Set dates (feature TBD)
%     NewEvents.AddDate(:) = ProcessDatetime;
%     NewEvents.UpdateDate(:) = ProcessDatetime;
%     
%     % Records without a processing time are assigned current time
%     NewEvents.ProcessDate(isnat(NewEvents.ProcessDate)) = ProcessDatetime;
% 
%     % Write data to Excel file
%     temporary = NewEvents;
%     temporary.Datetime = datestr(temporary.Datetime,'mm/dd/yyyy HH:MM:SS UTC');
%     NewEvents_xlsdata = [temporary.Properties.VariableNames; table2cell(temporary)];
%     output_filename = [scheduledfolder '\' now_datestring '_NewEventData.csv'];
%     
%     cd(scheduledfolder)
%     writecell(NewEvents_xlsdata, output_filename)
%     % xlswrite(output_filename_short,NewEvents_xlsdata)
%     % open file in Excel
%     % winopen(output_filename)
%     cd(mainfolder)
%     
%     
% % otherwise, report no events
% else
%     disp('No new events found.')
%     output_filename = 'NA';
%     NewEvents = array2table(zeros(0,0)); % empty table to satify function return
% end

% Save the database
save_database

% Re-enable table warnings
warning ('on','MATLAB:table:RowsAddedExistingVars')

% close program
close(handleNewEvents)
logformat([newline num2str(num_reviewed) ' Meteor Events Reviewed.  ' newline num2str(num_new) ' Events Added.' newline num2str(num_updated), ' Events Updated.'])
[~,codefilename,~] = fileparts(mfilename('fullpath'));
logformat([upper(codefilename) ' completed.'])
diary off
warning('Diary disabled after GETNEW_TEST');


